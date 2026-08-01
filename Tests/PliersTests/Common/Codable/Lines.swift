import Foundation
import Testing

@testable import PliersCommon

@Test func testLinesInitializerTreatsNilAsEmpty() {
	let lines = Lines(nil)
	#expect(lines.wrappedValue.isEmpty)
}

@Test func testLinesDecodingSplitsAndTrims() throws {
	let data = Data(#"" a\n\n b \n c ""#.utf8)
	let lines = try JSONDecoder().decode(Lines.self, from: data)

	#expect(lines.wrappedValue == ["a", "b", "c"])
}

@Test func testLinesEncodingJoinsWithNewline() throws {
	let lines = Lines(["a", "b", "c"])
	let encoded = try JSONEncoder().encode(lines)
	let value = try JSONDecoder().decode(String.self, from: encoded)

	#expect(value == "a\nb\nc")
}
