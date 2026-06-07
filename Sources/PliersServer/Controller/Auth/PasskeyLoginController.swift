import Fluent
import Vapor
import VaporElementary

struct PasskeyLoginController: RouteCollection {
	struct Credentials: Content {
		// TODO: https://www.swift.org/documentation/server/guides/passkeys.html
		let passkey: String
	}

	func boot(routes: any RoutesBuilder) throws {
		routes.get("login", "passkey", use: self.options)
		routes.grouped(User.requireLoggedOut())
			.post("login", "passkey", use: self.login)
	}

	@Sendable
	func options(req: Request) async throws -> String {
		// TODO: return passkey options
		return "TODO"
	}

	@Sendable
	func login(req: Request) async throws -> Response {
		let credentials = try req.content.decode(Credentials.self)

		// TODO: authenticate with passkey
		print(credentials)

		return req.redirect(to: "/dashboard")
	}
}
