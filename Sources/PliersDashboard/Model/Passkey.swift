import Fluent
import Vapor

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Passkey: Model, @unchecked Sendable {
	static let schema = "passkey"

	@ID
	var id: UUID?

	@Field(key: "credential_id")
	var credentialId: Data

	@Field(key: "public_key")
	var publicKey: Data

	@Field(key: "sign_count")
	var signCount: UInt32

	@Field(key: "last_used")
	var lastUsed: Date?

	@Field(key: "name")
	var name: String

	@Parent(key: "user_id")
	var user: User

	init() {}

	init(
		credentialId: Data,
		publicKey: Data,
		signCount: UInt32,
		name: String,
	) {
		self.credentialId = credentialId
		self.publicKey = publicKey
		self.signCount = signCount
		self.name = name
	}

	public static func find(credentialId: Data, on database: Database) async throws -> Passkey? {
		return try await Passkey.query(on: database)
			.filter(\.$credentialId == credentialId)
			.first()
	}
}
