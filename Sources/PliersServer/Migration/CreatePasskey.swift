import Fluent

struct CreatePasskey: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("passkey")
			.id()
			.field("credential_id", .data, .sql(.unique))
			.field("public_key", .data, .required)
			.field("sign_count", .uint32, .required)
			.field("last_used", .datetime)
			.field("name", .string, .required)
			.field("user_id", .uuid, .required, .references("user", .id, onDelete: .cascade))
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("passkey").delete()
	}
}
