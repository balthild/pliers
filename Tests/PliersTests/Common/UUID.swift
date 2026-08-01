import Foundation
import Testing

@testable import PliersCommon

@Test func testUUIDBytes() throws {
	let uuid = try UUID(uuidString: "00010203-0405-0607-0809-0a0b0c0d0e0f").expect("valid UUID")
	#expect(uuid.bytes.count == 16)
	#expect(uuid.bytes == Array(0...15))
}
