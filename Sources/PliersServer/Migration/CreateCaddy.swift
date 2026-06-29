import Fluent
import SQLKit

struct CreateCaddy: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("caddy")
			.id()
			.field("domains", .string, .required)
			.field("config", .string, .required)
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("caddy").delete()
	}
}
