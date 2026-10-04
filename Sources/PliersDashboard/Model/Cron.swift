import Fluent
import Foundation

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Cron: Model, @unchecked Sendable {
	static let schema = "cron"

	@ID
	var id: UUID?

	@Parent(key: "user_id")
	var user: User

	@Field(key: "expr")
	var expr: String

	@Field(key: "command")
	var command: String

	init() {
		self.expr = ""
		self.command = ""
	}
}
