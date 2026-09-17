import Fluent

struct CreateUser: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("user")
			.id()
			.field("username", .string, .required, .sql(.unique))
			.field("password_hash", .string)
			.field("password_totp", .string)
			.field("token_pubkey", .data, .sql(.unique))
			.field("token_challenge", .data, .sql(.unique))
			.field("token_expiration", .datetime)
			.field("privileges", .json, .required, .sql(.default("[]")))
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("user").delete()
	}
}
