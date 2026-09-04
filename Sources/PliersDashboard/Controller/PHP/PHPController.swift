import Fluent
import Foundation
import Path
import PliersCommon
import Subprocess
import Vapor

struct PHPController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped(User.requireLoggedIn())

		group.group("php") { group in
			group.get(use: self.index)
			group.post("install", use: self.install)

			group.group(":version") { group in
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

		let installed = try await Package.list(name: .php, on: req.db)
			.sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }

		let manifest = "https://dl.static-php.dev/v3/php-bin/bulk/?format=json"
		let response = try await req.client.get(.init(string: manifest))

		#if arch(arm64)
			let pattern = /php-(\d+\.\d+\.\d+)-fpm-linux-aarch64.tar.gz/
		#else
			let pattern = /php-(\d+\.\d+\.\d+)-fpm-linux-x86_64.tar.gz/
		#endif

		let excluding = Set(installed.map { $0.version })

		let available = try response.content
			.decode([ManifestItem].self)
			.compactMap({ (item) -> View.Page.PHPListPage.Available? in
				guard !item.is_dir else { return nil }
				guard let match = try pattern.wholeMatch(in: item.name) else { return nil }
				guard !excluding.contains(String(match.1)) else { return nil }
				return (
					version: String(match.1),
					size: item.size,
					date: item.last_modified,
				)
			})
			.sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }

		return try await req.render {
			View.Page.PHPListPage(
				available: available,
				installed: installed,
			)
		}
	}

	@Sendable
	func install(req: Request) async throws -> Response {
		struct Input: Content {
			let version: String
		}

		let input = try req.content.decode(Input.self)

		let _ = try /\d+\.\d+\.\d+/.wholeMatch(in: input.version)
			.alert("invalid version")

		let records = try await Package.query(on: req.db)
			.filter(\.$name == .php)
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
		let version: String = try req.parameters.get("version")
			.alert("invalid version")

		let _ = try /\d+\.\d+\.\d+/.wholeMatch(in: version)
			.alert("invalid version")

		let target = Constants.pkgs / "php" / version
		try target.delete()

		try await Package.query(on: req.db)
			.filter(\.$name == .php)
			.filter(\.$version == version)
			.delete()

		return req.redirect(to: "/php")
	}
}
