import Fluent
import PliersCommon
import Vapor
import VaporElementary
import WebAuthn

struct PasskeySettingsController: RouteCollection {
	private let challengeSessionKey = "passkey_register_challenge"

	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("settings", "passkey")
			.grouped(User.requireLoggedIn())

		group.get(use: self.options)
		group.post(use: self.create)
		group.group(":id") { group in
			group.post("update", use: self.update)
			group.post("delete", use: self.delete)
		}
	}

	struct Options: Content {
		let publicKey: PublicKeyCredentialCreationOptions
	}

	@Sendable
	func options(req: Request) async throws -> Options {
		let user = try req.auth.require(User.self)

		let options = req.webAuthn.beginRegistration(
			user: .init(
				id: try user.requireID().bytes,
				name: user.username,
				displayName: user.username,
			)
		)

		req.session.data[self.challengeSessionKey] = options.challenge.base64

		return .init(publicKey: options)
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		struct Input: Content {
			let name: String
			let passkey: RegistrationCredential
		}

		let input = try req.content.decode(Input.self)

		guard !input.name.isEmpty else {
			throw AlertError("name cannot be empty")
		}

		let challenge = try req.session.data
			.remove(self.challengeSessionKey)
			.flatMap { [UInt8](decodingBase64: $0) }
			.expect("invalid passkey challenge")

		let credential = try await req.webAuthn.finishRegistration(
			challenge: challenge,
			credentialCreationData: input.passkey,
			confirmCredentialIDNotRegisteredYet: { id in
				let id = try URLEncodedBase64(id).decodedBytes
					.alert("invalid passkey credential id")

				let count = try await Passkey.query(on: req.db)
					.filter(\.$credentialId == Data(id))
					.count()

				return count == 0
			},
		)

		// the id in `confirmCredentialIDNotRegisteredYet` is url encoded base64
		// while the id here is standard base64
		// and both are provided as plain string
		// what a fucking shitty API design
		let id = try EncodedBase64(credential.id).decoded
			.alert("invalid passkey credential id")

		let passkey = Passkey(
			credentialId: id,
			publicKey: Data(credential.publicKey),
			signCount: credential.signCount,
			name: input.name,
		)

		let user = try req.auth.require(User.self)
		try await user.$passkeys.create(passkey, on: req.db)

		return .init(status: .noContent)
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		struct Input: Content {
			let name: String
		}

		let input = try req.content.decode(Input.self)

		guard !input.name.isEmpty else {
			throw AlertError("name cannot be empty")
		}

		let user = try req.auth.require(User.self)
		let passkey = try await req.find(user.$passkeys, "id")

		passkey.name = input.name
		try await passkey.update(on: req.db)

		return req.redirect(.back)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)
		let passkey = try await req.find(user.$passkeys, "id")
		try await passkey.delete(on: req.db)

		return req.redirect(.back)
	}
}
