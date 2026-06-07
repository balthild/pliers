import Fluent
import Vapor
import VaporElementary

struct DashboardController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let auth = routes.grouped(User.requireLoggedIn())
		auth.get("dashboard", use: self.dashboard)
	}

	@Sendable
	func dashboard(req: Request) async throws -> HTMLResponse {
		let user = try req.auth.require(User.self)

		return HTMLResponse {
			UI.Page.Dashboard(user: user)
		}
	}
}
