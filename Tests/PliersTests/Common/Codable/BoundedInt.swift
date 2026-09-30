import Foundation
import PliersCommon
import Testing

@Test func testBoundedIntDecodesWithinRange() throws {
	let clamp = try JSONDecoder().decode(BoundedInt<1, 9>.self, from: Data("5".utf8))
	#expect(clamp.rawValue == 5)
}

@Test func testBoundedIntRejectsOutOfRange() {
	#expect(throws: DecodingError.self) {
		try JSONDecoder().decode(BoundedInt<1, 9>.self, from: Data("10".utf8))
	}
	#expect(throws: DecodingError.self) {
		try JSONDecoder().decode(BoundedInt<1, 9>.self, from: Data("0".utf8))
	}
}

@Test func testBoundedIntEncodesRawValue() throws {
	let clamp = try JSONDecoder().decode(BoundedInt<1, 9>.self, from: Data("7".utf8))
	let data = try JSONEncoder().encode(clamp)
	#expect(String(data: data, encoding: .utf8) == "7")
}
