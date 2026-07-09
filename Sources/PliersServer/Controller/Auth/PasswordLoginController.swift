import Fluent
import PliersCommon
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
		guard let user, let password = user.password, let totp = user.totp else {
			let _ = try await req.password.async.verify("", created: req.placeholder.password)
			let _ = req.placeholder.totp.verify(credentials.totp)
			throw AlertError("invalid credentials")
		}

		let step1 = try await req.password.async.verify(credentials.password, created: password)
		let step2 = totp.verify(credentials.totp)
		guard step1 && step2 else {
			throw AlertError("invalid credentials")
		}

		req.auth.login(user)

		return req.redirect(to: "/")
	}
}
