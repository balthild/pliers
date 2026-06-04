import Fluent
import Vapor

struct UserPasswordAuthenticator: AsyncCredentialsAuthenticator {
	struct Credentials: Content {
		let username: String
		let password: String
		let totp: String
	}

	func authenticate(credentials: Credentials, for request: Request) async throws {
		do {
			let user = try await User.find(username: credentials.username, on: request.db)
			guard let user, user.password != nil, user.totp != nil else { return }

			guard user.totp!.verify(credentials.totp) else {
				return
			}

			guard try request.password.verify(credentials.password, created: user.password!) else {
				return
			}

			request.auth.login(user)
		} catch {
			request.logger.report(error: error)
		}
	}
}
