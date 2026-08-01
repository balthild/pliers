import Foundation
import Testing

@testable import PliersCommon

private struct FallbackModel: Codable {
	@Fallback var flag: Bool
	@Fallback var title: String
	@Fallback var optional: String?
}

@Test func testFallbackUsesDefaultForMissingKeys() throws {
	let data = Data("{}".utf8)
	let model = try JSONDecoder().decode(FallbackModel.self, from: data)

	#expect(model.flag == false)
	#expect(model.title == "")
	#expect(model.optional == nil)
}

@Test func testFallbackUsesDefaultForInvalidValues() throws {
	let data = Data("{\"flag\":\"invalid\",\"title\":123,\"optional\":123}".utf8)
	let model = try JSONDecoder().decode(FallbackModel.self, from: data)

	#expect(model.flag == false)
	#expect(model.title == "")
	#expect(model.optional == nil)
}

@Test func testFallbackWithValidValues() throws {
	let data = Data("{\"flag\":true,\"title\":\"valid\",\"optional\":\"abc\"}".utf8)
	let model = try JSONDecoder().decode(FallbackModel.self, from: data)

	#expect(model.flag == true)
	#expect(model.title == "valid")
	#expect(model.optional == "abc")
}
