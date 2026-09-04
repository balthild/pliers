import Fluent
import Vapor

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Package: Model, @unchecked Sendable {
	static let schema = "package"

	@ID
	var id: UUID?

	@Enum(key: "name")
	var name: Name

	@Field(key: "version")
	var version: String

	@Field(key: "metadata")
	var metadata: [String: String]

	init() {
		self.metadata = [:]
	}

	enum Name: String, Codable {
		case php
	}

	public static func list(
		name: Name,
		on database: Database,
	) async throws -> [Package] {
		return try await Package.query(on: database)
			.filter(\.$name == name)
			.all()
	}
}
