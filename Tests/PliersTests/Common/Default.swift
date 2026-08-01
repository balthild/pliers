import Testing

@testable import PliersCommon

@Test func testDefaultValues() {
	#expect(Never?.defaultValue == nil)
	#expect(Bool.defaultValue == false)
	#expect(String.defaultValue == "")
	#expect(Int.defaultValue == 0)
	#expect(Double.defaultValue == 0.0)
}
