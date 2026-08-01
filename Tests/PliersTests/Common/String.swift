import Testing

@testable import PliersCommon

@Test func testQuoteJSONEscapesString() {
	let value = "hello\n\"world\""
	#expect(value.quoteJSON == "\"hello\\n\\\"world\\\"\"")
}
