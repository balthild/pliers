import Fluent
import Vapor
import VaporElementary

struct LoginController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("login").grouped(User.requireLoggedOut())

		group.get(use: self.login)

		group.grouped(UserPasswordAuthenticator()).post("password", use: self.redirect)

		group.get("token", use: self.token)
		group.grouped(UserTokenAuthenticator()).post("token", use: self.redirect)

		group.get("passkey", use: self.passkey)
		group.grouped(UserPasskeyAuthenticator()).post("passkey", use: self.redirect)
	}

	@Sendable
	func login(req: Request) async throws -> HTMLResponse {
		return HTMLResponse {
			UI.Page.Auth.Login()
		}
	}

	@Sendable
	func token(req: Request) async throws -> String {
		let expiration = Date().addingTimeInterval(300)
		let payload = UserTokenAuthenticator.Payload(exp: .init(value: expiration))
		return try await req.jwt.sign(payload)
	}

	@Sendable
	func passkey(req: Request) async throws -> String {
		return "TODO: return passkey options"
	}

	@Sendable
	func redirect(req: Request) async throws -> Response {
		// authentication is handled by the middlewares
		return req.redirect(to: "/dashboard")
	}
}
