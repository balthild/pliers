import Fluent

struct CreatePackage: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("package")
			.id()
			.field("name", .string, .required)
			.field("version", .string, .required)
			.field("metadata", .string, .required)
			.unique(on: "name", "version")
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("package").delete()
	}
}
