import Fluent

struct CreateUser: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("user")
			.id()
			.field("username", .string)
			.field("password", .string)
			.field("totp", .string)
			.unique(on: "username")
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("user").delete()
	}
}
