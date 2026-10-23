import Fluent

struct CreateMySQLAccount: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("mysql_account")
			.id()
			.field("user_id", .uuid, .required, .references("user", .id, onDelete: .cascade))
			.field("username", .string, .required)
			.field("host", .string, .required)
			.unique(on: "username", "host")
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("mysql_account").delete()
	}
}
