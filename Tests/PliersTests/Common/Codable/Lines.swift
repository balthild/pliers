import Foundation
import PliersCommon
import Testing

@Test func testLinesDecodingSplitsAndTrims() throws {
	let data = Data(#"" a\n\n b \n c ""#.utf8)
	let lines = try JSONDecoder().decode(Lines.self, from: data)

	#expect(lines.wrappedValue == ["a", "b", "c"])
}

@Test func testLinesEncodingJoinsWithNewline() throws {
	let lines: Lines = ["a", "b", "c"]
	let encoded = try JSONEncoder().encode(lines)
	let value = try JSONDecoder().decode(String.self, from: encoded)

	#expect(value == "a\nb\nc")
}

private struct LinesHolder: Codable {
	@Lines var items: [String]
}

@Test func testLinesMissingKeyDecodesEmpty() throws {
	let holder = try JSONDecoder().decode(LinesHolder.self, from: Data("{}".utf8))
	#expect(holder.items.isEmpty)
}

@Test func testLinesPresentKeySplits() throws {
	let data = Data(#"{ "items": "a\n b \nc" }"#.utf8)
	let holder = try JSONDecoder().decode(LinesHolder.self, from: data)
	#expect(holder.items == ["a", "b", "c"])
}
