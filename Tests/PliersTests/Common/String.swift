import PliersCommon
import Testing

@Test func testQuoteJSONEscapesString() {
	let value = "hello\n\"world\""
	#expect(value.quoteJSON == "\"hello\\n\\\"world\\\"\"")
}

@Test func testQuoteMySQLEscapesQuotes() {
	#expect("it's".quoteMySQL == "'it''s'")
	#expect(#"a\b"#.quoteMySQL == #"'a\\b'"#)
}

@Test func testQuoteMySQLEscapesNUL() {
	#expect("\0".quoteMySQL == #"'\0'"#)
	// The backslash introducing `\0` must not be doubled by the backslash pass.
	#expect("a\0b".quoteMySQL == #"'a\0b'"#)
}

@Test func testQuoteMySQLIdentifierEscapesBackticks() {
	#expect("weird`name".quoteMySQLIdentifier == "`weird``name`")
}
