import Foundation

extension String {
	/// Quotes the receiver as a single-quoted MySQL string literal.
	///
	/// Backslashes are doubled first, so the backslash introducing the `NUL` escape is not
	/// doubled itself. The backslash handling assumes `NO_BACKSLASH_ESCAPES` is off, which is
	/// MySQL's default; the single quote is doubled, which is correct in every mode.
	public var quoteMySQL: String {
		let escaped =
			self
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "\0", with: "\\0")
			.replacingOccurrences(of: "'", with: "''")

		return "'\(escaped)'"
	}

	/// Quotes the receiver as a MySQL identifier (backtick-quoted).
	public var quoteMySQLIdentifier: String {
		return "`\(self.replacingOccurrences(of: "`", with: "``"))`"
	}
}
