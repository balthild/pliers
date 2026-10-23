import Fluent
import Foundation
import PliersCommon

/// A MySQL account created by Pliers.
///
/// Pliers only manages MySQL accounts it created itself, so every row records the panel user
/// that owns the account. The account password is never stored here: it is sent to MySQL
/// when set and can only be changed afterwards.
final class MySQLAccount: Model, @unchecked Sendable {
	static let schema = "mysql_account"

	@ID
	var id: UUID?

	@Parent(key: "user_id")
	var user: User

	@Field(key: "username")
	var username: String

	@Field(key: "host")
	var host: String

	init() {
		self.username = ""
		self.host = "localhost"
	}
}

extension MySQLAccount {
	/// The account as MySQL expects it in SQL, e.g. `'app'@'localhost'`.
	var quoteMySQL: String {
		return "\(self.username.quoteMySQL)@\(self.host.quoteMySQL)"
	}

	/// Validates and stores the account name.
	///
	/// MySQL accepts account names only as SQL syntax, never as bound parameters, so the
	/// username and host are restricted to a safe ASCII charset before being embedded into a
	/// statement.
	func prepare(username: String, host: String) throws {
		let username = username.trimmed
		let host = host.trimmed

		guard username.wholeMatch(of: Self.usernamePattern) != nil else {
			throw AlertError("invalid mysql username")
		}

		guard host.wholeMatch(of: Self.hostPattern) != nil else {
			throw AlertError("invalid mysql host")
		}

		self.username = username
		self.host = host
	}

	// A deliberate ASCII allowlist rather than `\w`, which is Unicode-aware and omits `-` and
	// `.`. The leading character is restricted so a name cannot begin with `-` (read as an
	// option by the mysql CLI) or `.`.
	private static var usernamePattern: Regex<Substring> { /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,31}$/ }
	private static var hostPattern: Regex<Substring> { /^[A-Za-z0-9_.%:-]{1,255}$/ }
}
