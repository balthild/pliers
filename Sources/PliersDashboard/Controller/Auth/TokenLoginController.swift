import Crypto
import Fluent
import Foundation
import PliersCommon
import Vapor
import VaporElementary

struct TokenLoginController: RouteCollection {
	struct Credentials: Content {
		let token: String
	}

	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedOut())
			.post("login", "token", use: self.login)
	}

	@Sendable
	func login(req: Request) async throws -> Response {
		let credentials = try req.content.decode(Credentials.self)

		let parts = credentials.token.split(separator: ";")
		guard parts.count == 2 else {
			throw AlertError("invalid token")
		}

		let pubkey = try Data(base64Encoded: String(parts[0]))
			.flatMap { try? Curve25519.Signing.PublicKey(rawRepresentation: $0) }
			.alert("invalid token")

		let signature = try Data(base64Encoded: String(parts[1]))
			.alert("invalid token")

		let user = try await User.query(on: req.db)
			.filter(\.$token.$pubkey == pubkey.rawRepresentation)
			.first()

		guard let user, let token = user.token, token.expiration > .now else {
			throw AlertError("invalid token")
		}

		guard pubkey.isValidSignature(signature, for: token.challenge) else {
			throw AlertError("invalid token")
		}

		user.token = nil
		try await user.save(on: req.db)

		req.auth.login(user)

		return req.redirect(to: "/")
	}
}
