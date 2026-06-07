import Fluent
import Foundation
import JWT
import PliersCommon
import Vapor
import VaporElementary

struct TokenLoginController: RouteCollection {
	struct Credentials: Content {
		let username: String
		let token: String
	}

	struct Payload: JWTPayload {
		var exp: ExpirationClaim

		func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
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
		let expiration = Date().addingTimeInterval(300)
		let payload = Payload(exp: .init(value: expiration))
		return try await req.jwt.sign(payload)
	}

	@Sendable
	func login(req: Request) async throws -> Response {
		let credentials = try req.content.decode(Credentials.self)

		let home = try FileManager.default.homeDirectory(forUser: credentials.username)
			.expect("get home dir for user")
		let file = home.appending(path: Constants.userTokenPath)

		let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
		if attrs[.posixPermissions] as? UInt16 != 0o600 {
			throw RuntimeError("token file must not be accessible by other users")
		}

		let data = try await req.fileio.collectFile(at: file.path)
		try await req.jwt.verify(Data(buffer: data), as: Payload.self)

		let user = try await User.findOrCreate(username: credentials.username, on: req.db)

		req.auth.login(user)

		return req.redirect(to: "/dashboard")
	}
}
