import Fluent
import Foundation
import Vapor

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class User: Model, @unchecked Sendable {
	static let schema = "user"

	@ID
	var id: UUID?

	@Field(key: "username")
	var username: String

	@OptionalField(key: "password")
	var password: String?

	@OptionalField(key: "totp")
	var totp: TOTPConfig?

	init() {}

	public static func find(username: String, on database: Database) async throws -> User? {
		return try await User.query(on: database)
			.filter(\.$username == username)
			.first()
	}

	public static func findOrCreate(username: String, on database: Database) async throws -> User {
		let existing = try await Self.find(username: username, on: database)
		if let existing {
			return existing
		}

		let creating = User()
		creating.username = username

		try await creating.create(on: database)
		return creating
	}
}

extension User: ModelSessionAuthenticatable {}

extension User {
	/// Redirect unauthenticated requests
	public static func requireLoggedIn() -> [Middleware] {
		return [
			User.sessionAuthenticator(),
			User.redirectMiddleware(path: "/login"),
		]
	}

	/// Redirect authenticated requests
	public static func requireLoggedOut() -> [Middleware] {
		return [
			User.sessionAuthenticator(),
			User.guestMiddleware(path: "/dashboard"),
		]
	}
}
