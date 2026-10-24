import Fluent

struct CreateMySQL: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("mysql")
			.id()
			.field("user_id", .uuid, .required, .references("user", .id, onDelete: .cascade))
			.field("database", .string, .required)
			.field("username", .string, .required)
			.field("host", .string, .required)
			.unique(on: "database")
			.unique(on: "username", "host")
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("mysql").delete()
	}
}
