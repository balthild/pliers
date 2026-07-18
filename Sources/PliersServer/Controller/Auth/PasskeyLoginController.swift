import Fluent
import PliersCommon
import Vapor
import VaporElementary
import WebAuthn

struct PasskeyLoginController: RouteCollection {
	private let challengeSessionKey = "passkey_login_challenge"

	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedOut())
			.get("login", "passkey", use: self.options)
		routes.grouped(User.requireLoggedOut())
			.post("login", "passkey", use: self.login)
	}

	struct Options: Content {
		let publicKey: PublicKeyCredentialRequestOptions
	}

	struct Credentials: Content {
		let passkey: AuthenticationCredential
	}

	@Sendable
	func options(req: Request) async throws -> Options {
		let options = req.webAuthn.beginAuthentication(userVerification: .preferred)
		req.session.data[self.challengeSessionKey] = options.challenge.base64

		return .init(publicKey: options)
	}

	@Sendable
	func login(req: Request) async throws -> Response {
		let failure = "invalid credentials"

		let credentials = try rethrowing(alert: failure, chain: false) {
			try req.content.decode(Credentials.self)
		}

		let challenge = try rethrowing(alert: failure, chain: false) {
			return try req.session.data
				.remove(self.challengeSessionKey)
				.flatMap { [UInt8](decodingBase64: $0) }
				.expect("invalid passkey challenge")
		}

		guard let id = credentials.passkey.id.decodedBytes.map({ Data($0) }) else {
			throw AlertError(failure)
		}

		guard let passkey = try await Passkey.find(credentialId: id, on: req.db) else {
			throw AlertError(failure)
		}

		let verified = try rethrowing(alert: failure, chain: false) {
			try req.webAuthn.finishAuthentication(
				credential: credentials.passkey,
				expectedChallenge: challenge,
				credentialPublicKey: [UInt8](passkey.publicKey),
				credentialCurrentSignCount: passkey.signCount,
				requireUserVerification: false,
			)
		}

		passkey.signCount = verified.newSignCount
		passkey.lastUsed = .now
		try await passkey.update(on: req.db)

		let user = try await passkey.$user.get(on: req.db)
		req.auth.login(user)

		return .init(status: .noContent)
	}
}
