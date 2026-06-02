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
			let file = home.appending(path: ".config/pliers/token")

			let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
			let mode = attrs[.posixPermissions] as? Int
			if mode != 0o600 {
				throw RuntimeError("unexpected permission for token file")
			}

			let data = try Data(contentsOf: file)
			try await request.jwt.verify(data, as: Payload.self)
		} catch {
			request.logger.report(error: error)
		}
	}
}
