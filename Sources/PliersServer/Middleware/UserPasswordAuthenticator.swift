import Fluent
import Vapor

struct UserPasswordAuthenticator: AsyncCredentialsAuthenticator {
	struct Credentials: Content {
		let username: String
		let password: String
		let totp: String
	}

	func authenticate(credentials: Credentials, for request: Request) async throws {
		// TODO: authenticate with password and totp
		// https://docs.vapor.codes/security/crypto/#totp
	}
}
