import Fluent
import Foundation
import PliersCommon

/// A MySQL database and its dedicated user, created by Pliers.
///
/// Every row pairs exactly one database with one MySQL account, so the panel never leaves a
/// standalone account behind. The password is never stored here: it is sent to MySQL when set
/// and can only be changed afterwards.
final class MySQL: Model, @unchecked Sendable {
	static let schema = "mysql"

	@ID
	var id: UUID?

	@Parent(key: "user_id")
	var user: User

	@Field(key: "database")
	var database: String

	@Field(key: "username")
	var username: String

	@Field(key: "host")
	var host: String

	@Field(key: "charset")
	var charset: Charset

	init() {
		self.database = ""
		self.username = ""
		self.host = "localhost"
		self.charset = .utf8mb4
	}
}

extension MySQL {
	/// The database character set. A curated allowlist keeps the value safe to embed in SQL.
	enum Charset: String, Codable, CaseIterable, Sendable {
		case utf8mb4
		case utf8mb3
		case latin1
		case ascii
		case binary
	}

	/// The database name as MySQL expects it in SQL, e.g. `` `app` ``.
	var quoteDatabase: String {
		return self.database.quoteMySQLIdentifier
	}

	/// The user as MySQL expects it in SQL, e.g. `'app'@'localhost'`.
	var quoteAccount: String {
		return "\(self.username.quoteMySQL)@\(self.host.quoteMySQL)"
	}

	/// Validates and stores the database and user names.
	///
	/// MySQL accepts database and account names only as SQL syntax, never as bound parameters,
	/// so they are restricted to a safe ASCII charset before being embedded into a statement.
	func prepare(database: String, username: String, host: String, charset: String) throws {
		let database = database.trimmed
		let username = username.trimmed
		let host = host.trimmed
		let charset = charset.trimmed

		guard database.wholeMatch(of: Self.databasePattern) != nil else {
			throw AlertError("invalid mysql database")
		}

		guard username.wholeMatch(of: Self.usernamePattern) != nil else {
			throw AlertError("invalid mysql username")
		}

		guard host.wholeMatch(of: Self.hostPattern) != nil else {
			throw AlertError("invalid mysql host")
		}

		guard let charset = Charset(rawValue: charset) else {
			throw AlertError("invalid mysql charset")
		}

		self.database = database
		self.username = username
		self.host = host
		self.charset = charset
	}

	// A deliberate ASCII allowlist rather than `\w`, which is Unicode-aware and omits `-` and
	// `.`. The leading character is restricted so a name cannot begin with `-` (read as an
	// option by the mysql CLI) or `.`.
	private static var databasePattern: Regex<Substring> { /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,63}$/ }
	private static var usernamePattern: Regex<Substring> { /^[A-Za-z0-9_][A-Za-z0-9_.-]{0,31}$/ }
	private static var hostPattern: Regex<Substring> { /^[A-Za-z0-9_.%:-]{1,255}$/ }
}
