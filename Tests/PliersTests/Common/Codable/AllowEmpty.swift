import Foundation
import PliersCommon
import Testing

private struct Holder: Codable {
	@AllowEmpty var value: Int?

	init(value: Int?) {
		self.value = value
	}
}

@Test func testAllowEmptyTreatsEmptyStringAsNil() throws {
	let holder = try JSONDecoder().decode(Holder.self, from: Data(#"{ "value": "" }"#.utf8))
	#expect(holder.value == nil)
}

@Test func testAllowEmptyDecodesPresentValue() throws {
	let holder = try JSONDecoder().decode(Holder.self, from: Data(#"{ "value": 5 }"#.utf8))
	#expect(holder.value == 5)
}

@Test func testAllowEmptyMissingKeyIsNil() throws {
	let holder = try JSONDecoder().decode(Holder.self, from: Data("{}".utf8))
	#expect(holder.value == nil)
}

@Test func testAllowEmptyRejectsInvalidValue() {
	#expect(throws: DecodingError.self) {
		try JSONDecoder().decode(Holder.self, from: Data(#"{ "value": "abc" }"#.utf8))
	}
}
