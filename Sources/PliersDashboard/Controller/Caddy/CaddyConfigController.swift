import Path
import PliersCommon
import Subprocess
import Vapor

struct CaddyConfigController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.caddy))
			.group("caddy", "config") { group in
				group.post("apply", use: self.apply)
			}
	}

	func apply(req: Request) async throws -> Response {
		let dir = try await Self.generate(req: req)

		try await Result { try await Self.validate(dir: dir) }
			.alert("invalid caddy config generated")

		defer { try? dir.delete() }

		let live = dir.parent / "live"
		try live.mkdir()
		try live.replace(with: dir)

		return req.redirect(.back)
	}

	private static func generate(req: Request) async throws -> Path {
		let base = C.caddy.conf / "pliers"
		try base.mkdir(.p)

		let dir = try base.mkrand(.dir)
		let file = dir / "Caddyfile"

		let sites = try await Caddy.query(on: req.db).all()

		try await Self.mkdir(sites: sites)

		let caddyfile = Caddyfile.build {
			Caddyfile.item {
				Caddyfile.item("admin", "off")
			}

			for site in sites {
				Caddyfile.site(site, app: req.application)
			}
		}

		let buffer = req.byteBufferAllocator.buffer(string: caddyfile)
		try await req.fileio.writeFile(buffer, at: file.string)

		return dir
	}

	private static func validate(dir: Path) async throws {
		let file = dir / "Caddyfile"

		let result = try await Subprocess.run(
			.path(C.caddy.exec),
			arguments: ["validate", "--config", file.string],
			environment: .custom([]),
			platformOptions: try .su(C.caddy.user),
			input: .none,
			output: .discarded,
			error: .sequence,
			body: { try await $0.standardError.lastLine() },
		)

		guard case .exited(0) = result.terminationStatus else {
			try? dir.delete()
			throw RuntimeError(result.closureResult)
		}
	}

	private static func mkdir(sites: [Caddy]) async throws {
		for site in sites where site.config.logging.enable {
			let output = site.config.logging.output.trimmed
			guard !output.isEmpty, let file = Path(output) else {
				continue
			}

			// only manage standard web log locations
			let dir = file.parent
			guard dir.hasPrefix(C.caddy.log) else {
				continue
			}

			try dir.mkdir(.p)
			try dir.chown(owner: C.caddy.user, group: C.caddy.user)
		}
	}
}
