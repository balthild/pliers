import Vapor
import VaporElementary

struct CaddyController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("caddy").grouped(User.requireLoggedIn())
		group.get(use: self.index)
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		let sites = try await Caddy.query(on: req.db).all()

		return try await req.render {
			UI.Page.Caddy.List(
				sites: sites
			)
		}
	}

}
