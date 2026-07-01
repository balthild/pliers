import Fluent
import Vapor
import VaporElementary

struct HomeController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedIn()).get(use: self.overview)
	}

	@Sendable
	func overview(req: Request) async throws -> Response {
		return try await req.render {
			View.Page.OverviewPage()
		}
	}
}
