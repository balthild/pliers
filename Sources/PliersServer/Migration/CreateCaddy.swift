import Fluent
import SQLKit

struct CreateCaddy: AsyncMigration {
	func prepare(on database: any Database) async throws {
		try await database.schema("caddy")
			.id()
			.field("domains", .string, .required)
			.field("tls", .string)
			.field("backend", .string)
			.field("custom", .string, .required, .sql(.default("")))
			.create()
	}

	func revert(on database: any Database) async throws {
		try await database.schema("caddy").delete()
	}
}
