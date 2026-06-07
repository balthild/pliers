import Fluent
import Vapor
import VaporElementary

struct DashboardController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped(User.requireLoggedIn())
		group.get("dashboard", use: self.dashboard)
	}

	@Sendable
	func dashboard(req: Request) async throws -> HTMLResponse {
		let user = try req.auth.require(User.self)

		return HTMLResponse {
			UI.Page.Dashboard(user: user)
		}
	}
}
