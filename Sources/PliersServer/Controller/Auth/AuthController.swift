import Fluent
import Vapor
import VaporElementary

struct AuthController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedOut()).get("login", use: self.login)
		routes.grouped(User.requireLoggedIn()).post("logout", use: self.logout)
	}

	@Sendable
	func login(req: Request) async throws -> Response {
		return try await req.render {
			UI.Page.Login()
		}
	}

	@Sendable
	func logout(req: Request) async throws -> Response {
		req.auth.logout(User.self)
		return req.redirect(to: "/login")
	}
}
