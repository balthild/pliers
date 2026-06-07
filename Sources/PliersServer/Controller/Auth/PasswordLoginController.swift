import Fluent
import Vapor
import VaporElementary

struct PasswordLoginController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedOut())
			.post("login", "password", use: self.login)
	}

	struct Credentials: Content {
		let username: String
		let password: String
		let totp: String
	}

	@Sendable
	func login(req: Request) async throws -> Response {
		let credentials = try req.content.decode(Credentials.self)

		let user = try await User.find(username: credentials.username, on: req.db)
		guard let user, user.password != nil, user.totp != nil else {
			throw Abort(.unauthorized)
		}

		guard user.totp!.verify(credentials.totp) else {
			throw Abort(.unauthorized)
		}

		guard try req.password.verify(credentials.password, created: user.password!) else {
			throw Abort(.unauthorized)
		}

		req.auth.login(user)

		return req.redirect(to: "/dashboard")
	}
}
