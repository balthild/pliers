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

	@Field(key: "password")
	var password: String?

	@Field(key: "totp")
	var totp: String?

	init() {}
}

extension User: ModelSessionAuthenticatable {}

extension User {
	/// Redirect unauthenticated requests
	public static func requireLoggedIn() -> [Middleware] {
		return [
			User.sessionAuthenticator(),
			User.redirectMiddleware(path: "login"),
		]
	}

	/// Redirect authenticated requests
	public static func requireLoggedOut() -> [Middleware] {
		return [
			User.sessionAuthenticator(),
			User.guestMiddleware(path: "dashboard"),
		]
	}
}
