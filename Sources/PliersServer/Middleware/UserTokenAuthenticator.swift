import Fluent
import Foundation
import JWT
import PliersCommon
import Vapor

struct UserTokenAuthenticator: AsyncCredentialsAuthenticator {
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

	func authenticate(credentials: Credentials, for request: Request) async throws {
		do {
			let home = try FileManager.default.homeDirectory(forUser: credentials.username)
				.expect("get home dir for user")
			let file = home.appending(path: Constants.userTokenPath)

			let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
			if attrs[.posixPermissions] as? UInt16 != 0o600 {
				throw RuntimeError("token file must not be accessible by other users")
			}

			let data = try Data(contentsOf: file)
			try await request.jwt.verify(data, as: Payload.self)

			let user = try await User.findOrCreate(username: credentials.username, on: request.db)
			request.auth.login(user)
		} catch {
			request.logger.report(error: error)
		}
	}
}
