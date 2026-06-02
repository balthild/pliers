import Fluent
import Vapor

struct LogoutController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("/logout").grouped(User.requireLoggedIn())

		group.post("/", use: self.logout)
	}

	@Sendable
	func logout(req: Request) async throws -> Response {
		req.auth.logout(User.self)
		return req.redirect(to: "/login")
	}
}
