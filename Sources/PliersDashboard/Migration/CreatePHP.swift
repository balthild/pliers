import Fluent

struct CreatePHP: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("php")
			.id()
			.field("version", .string, .required, .sql(.unique))
			.field("config", .json, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("php").delete()
	}
}
