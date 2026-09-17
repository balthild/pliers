import PliersCommon
import Testing

@Test func testQuoteJSONEscapesString() {
	let value = "hello\n\"world\""
	#expect(value.quoteJSON == "\"hello\\n\\\"world\\\"\"")
}
