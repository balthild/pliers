import Fluent
import Foundation
import JWT
import Path
import PliersCommon
import Vapor
import VaporElementary

struct TokenLoginController: RouteCollection {
	struct Credentials: Content {
		let token: String
	}

	struct Payload: JWTPayload {
		var sub: SubjectClaim
		var nbf: NotBeforeClaim
		var exp: ExpirationClaim

		func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
			try self.nbf.verifyNotBefore()
			try self.exp.verifyNotExpired()
		}
	}

	func boot(routes: any RoutesBuilder) throws {
		routes.get("login", "token", use: self.generate)
		routes.grouped(User.requireLoggedOut())
			.post("login", "token", use: self.login)
	}

	@Sendable
	func generate(req: Request) async throws -> String {
		let username: String = try req.query["username"]
			.alert("username is required")

		let payload = Payload(
			sub: .init(value: username),
			nbf: .init(value: .now),
			exp: .init(value: .now.addingTimeInterval(300)),
		)

		return try await req.jwt.sign(payload)
	}

	@Sendable
	func login(req: Request) async throws -> Response {
		let credentials = try req.content.decode(Credentials.self)

		let parts = credentials.token.split(separator: ";")
		guard parts.count == 2 else {
			throw AlertError("invalid token")
		}

		let payload = try await req.jwt.verify(String(parts[0]), as: Payload.self)

		let home = try Path.home(for: payload.sub.value).alert("invalid token")
		let path = home / Constants.userTokenFile

		let attrs = try path.attrs.alert("failed to check token file")
		if attrs[.posixPermissions] as? UInt16 != 0o600 {
			throw AlertError("token file must not be accessible by other users")
		}

		let stored = try await req.fileio.collectFile(at: path.string)
		guard stored == .init(string: credentials.token) else {
			throw AlertError("invalid token")
		}

		try Result { try path.delete() }.alert("invalid token file status")

		let user = try await User.findOrCreate(username: payload.sub.value, on: req.db)
		req.auth.login(user)

		return req.redirect(to: "/")
	}
}
