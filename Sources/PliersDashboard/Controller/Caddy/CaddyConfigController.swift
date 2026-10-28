import Path
import PliersCommon
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

		try await Result { try await Caddyfile.validate(dir: dir, su: true) }
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

		let caddyfile = try Caddyfile.build {
			Caddyfile.item {
				Caddyfile.item("admin", "off")
			}

			for site in sites {
				try Caddyfile.site(site, app: req.application)
			}
		}

		let buffer = req.byteBufferAllocator.buffer(string: caddyfile)
		try await req.fileio.writeFile(buffer, at: file.string)

		return dir
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
