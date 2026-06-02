import Fluent
import Vapor

struct UserPasskeyAuthenticator: AsyncCredentialsAuthenticator {
	struct Credentials: Content {
		// TODO: https://www.swift.org/documentation/server/guides/passkeys.html
		let passkey: String
	}

	func authenticate(credentials: Credentials, for request: Request) async throws {
		// TODO: authenticate with passkey
	}
}
