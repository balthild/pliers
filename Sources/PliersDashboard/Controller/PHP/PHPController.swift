import Fluent
import Foundation
import Path
import PliersCommon
import Subprocess
import Vapor

struct PHPController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.php))
			.group("php") { group in
				group.get(use: self.index)
				group.post("install", use: self.install)

				group.group(":version") { group in
					group.get(use: self.settings)
					group.post("update", use: self.update)
					group.post("remove", use: self.remove)
				}
			}
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		struct ManifestItem: Codable {
			let is_dir: Bool
			let name: String
			let size: String
			let last_modified: String
		}

		let installed = try await PHP.query(on: req.db).all()
			.sorted { $0.version < $1.version }

		let statuses = [String: String](
			await req.dbus.systemd
				.manager { try await $0.listUnitsByNames(names: installed.map(\.configurator.service)) }
				.success
				.flatMap(\.array)
				.unwrapOr([])
				.compactMap { value in
					guard let fields = value.structure else { return nil }
					guard let name = fields[maybe: 0]?.string else { return nil }
					guard let status = fields[maybe: 3]?.string else { return nil }
					return (name, status)
				},
			uniquingKeysWith: { $1 },
		)

		let manifest = "https://dl.static-php.dev/v3/php-bin/bulk/?format=json"
		let response = try await req.client.get(.init(string: manifest))

		#if arch(arm64)
			let pattern = /php-(\d+\.\d+\.\d+)-fpm-linux-aarch64.tar.gz/
		#else
			let pattern = /php-(\d+\.\d+\.\d+)-fpm-linux-x86_64.tar.gz/
		#endif

		let excluding = Set(installed.map(\.version))
		let available = try response.content
			.decode([ManifestItem].self)
			.compactMap({ item -> View.Page.PHPListPage.Available? in
				guard !item.is_dir else { return nil }
				guard let match = try pattern.wholeMatch(in: item.name) else { return nil }
				guard let version = try? PHP.Version(parse: match.1) else { return nil }
				guard !excluding.contains(version) else { return nil }
				return (
					version: version,
					size: item.size,
					date: item.last_modified,
				)
			})
			.sorted { $0.version < $1.version }

		return try await req.render {
			View.Page.PHPListPage(
				available: available,
				installed: installed,
				statuses: statuses,
			)
		}
	}

	@Sendable
	func install(req: Request) async throws -> Response {
		struct Input: Content {
			let version: PHP.Version
		}

		let input = try req.content.decode(Input.self)

		let records = try await PHP.query(on: req.db)
			.filter(\.$version == input.version)
			.count()
		guard records == 0 else {
			throw AlertError("PHP \(input.version) already installed")
		}

		let progress = try await req.progress.create()
		let snapshot = await progress.snapshot()

		try await req.queue.dispatch(
			InstallPHPJob.self,
			.init(id: progress.id, version: input.version),
		)

		return try await req.render {
			View.Page.ProgressPage(
				id: progress.id,
				snapshot: snapshot,
				redirect: "/php",
				title: "PHP",
			)
		}
	}

	@Sendable
	func remove(req: Request) async throws -> Response {
		let model = try await req.find(\PHP.$version, "version")

		let sites = try await Self.sites(referencing: model, on: req.db)
		guard sites.isEmpty else {
			let domains = sites.flatMap(\.domains).joined(separator: ", ")
			throw AlertError("PHP \(model.version) is still used by: \(domains)")
		}

		let target = C.pkgs / "php" / model.version.string
		try target.delete()

		try await model.delete(on: req.db)

		let configurator = model.configurator
		try? configurator.dir.delete()
		if configurator.unit.exists {
			try configurator.unit.delete()
			try await Self.daemonReload(req)
		}

		return req.redirect(to: "/php")
	}

	@Sendable
	func settings(req: Request) async throws -> Response {
		let model = try await req.find(\PHP.$version, "version")

		// the unit may not exist yet if the configuration has never been applied
		let status = try? await req.dbus.systemd.status(model.configurator.service).get()

		return try await req.render {
			View.Page.PHPSettingsPage(
				model: model,
				status: status ?? "inactive",
			)
		}
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		let model = try await req.find(\PHP.$version, "version")

		let sites = try await Self.sites(referencing: model, on: req.db)

		try Self.prepare(req: req, into: model)

		let configurator = model.configurator
		guard configurator.binary.exists else {
			throw AlertError("php-fpm binary not found for PHP \(model.version)")
		}

		try configurator.base.mkdir(.p)

		let tmp = try configurator.base.mkrand(.dir)
		defer { try? tmp.delete() }

		let fpm = configurator.buildFPM(config: model.config)
		try await req.fileio.writeFile(
			req.byteBufferAllocator.buffer(string: fpm),
			at: (tmp / "php-fpm.conf").string,
		)

		let ini = configurator.buildINI(config: model.config)
		try await req.fileio.writeFile(
			req.byteBufferAllocator.buffer(string: ini),
			at: (tmp / "php.ini").string,
		)

		try await Self.validate(tmp: tmp, configurator: configurator)

		try await req.db.transaction { db in
			try await Self.repoint(sites: sites, to: model, on: db)

			try await model.update(on: db)
			try await Self.writeUnit(req: req, configurator: configurator)

			try configurator.dir.mkdir()
			try configurator.dir.replace(with: tmp)
		}

		return req.redirect(.back)
	}

	private static func sites(referencing model: PHP, on db: any Database) async throws -> [Caddy] {
		let address = model.config.caddyListenAddress(version: model.version)
		return try await Caddy.query(on: db).all().filter { site in
			site.config.backend?[case: \.php]?.fpm == address
		}
	}

	private static func repoint(sites: [Caddy], to model: PHP, on db: any Database) async throws {
		let address = model.config.caddyListenAddress(version: model.version)

		for site in sites {
			guard case .php(let php) = site.config.backend else { continue }
			site.config.backend = .php(.init(root: php.root, fpm: address))

			try await site.update(on: db)
		}
	}

	private static func prepare(req: Request, into model: PHP) throws {
		struct Input: Content {
			let config: PHP.Config
		}

		let input = try req.content.decode(Input.self)

		guard input.config.maxChildren >= 1 else {
			throw AlertError("max_children must be at least 1")
		}

		guard input.config.startServers >= 1 else {
			throw AlertError("start_servers must be at least 1")
		}

		guard input.config.minSpareServers >= 1 else {
			throw AlertError("min_spare_servers must be at least 1")
		}

		guard input.config.maxSpareServers >= input.config.minSpareServers else {
			throw AlertError("max_spare_servers must not be less than min_spare_servers")
		}

		guard input.config.maxSpareServers <= input.config.maxChildren else {
			throw AlertError("max_spare_servers must not exceed max_children")
		}

		guard input.config.terminateTimeout >= 0 else {
			throw AlertError("invalid request_terminate_timeout")
		}

		model.config = input.config
	}

	private static func validate(tmp: Path, configurator: PHPConfigurator) async throws {
		let fpm = tmp / "php-fpm.conf"
		let ini = tmp / "php.ini"

		let result = try await Subprocess.run(
			.path(configurator.binary),
			arguments: ["--test", "--php-ini", ini.string, "--fpm-config", fpm.string],
			environment: .custom([]),
			input: .none,
			output: .discarded,
			error: .sequence,
			body: { try await $0.standardError.lastLine() },
		)

		guard case .exited(0) = result.terminationStatus else {
			try? tmp.delete()
			throw RuntimeError(result.closureResult)
		}
	}

	private static func writeUnit(req: Request, configurator: PHPConfigurator) async throws {
		let text = configurator.buildUnit()
		let buffer = req.byteBufferAllocator.buffer(string: text)
		try await req.fileio.writeFile(buffer, at: configurator.unit.string)

		try await daemonReload(req)
	}

	private static func daemonReload(_ req: Request) async throws {
		let _ = try await req.dbus.systemd
			.manager { try await $0.reload() }
			.alert("failed to reload systemd")
	}
}
