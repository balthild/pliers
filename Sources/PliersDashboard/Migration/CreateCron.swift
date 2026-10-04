import Fluent

struct CreateCron: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("cron")
			.id()
			.field("user_id", .uuid, .required, .references("user", .id, onDelete: .cascade))
			.field("expr", .string, .required)
			.field("command", .string, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("cron").delete()
	}
}
