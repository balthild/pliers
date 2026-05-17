import Fluent

struct CreateUser: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("user")
			.field("id", .uint32, .identifier(auto: false))
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("user").delete()
	}
}
