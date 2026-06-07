import Fluent
import Foundation
import JWT
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
			.expect("username is required")

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
			throw Abort(.badRequest, reason: "invalid token")
		}

		let payload = try await req.jwt.verify(String(parts[0]), as: Payload.self)

		let home = try FileManager.default.homeDirectory(forUser: payload.sub.value)
			.expect("get home dir for user")
		let file = home.appending(path: Constants.userTokenPath)

		let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
		if attrs[.posixPermissions] as? UInt16 != 0o600 {
			throw RuntimeError("token file must not be accessible by other users")
		}

		let stored = try await req.fileio.collectFile(at: file.path)
		guard stored == .init(string: credentials.token) else {
			throw Abort(.unauthorized, reason: "invalid token")
		}

		try FileManager.default.removeItem(at: file)

		let user = try await User.findOrCreate(username: payload.sub.value, on: req.db)
		req.auth.login(user)

		return req.redirect(to: "/dashboard")
	}
}
