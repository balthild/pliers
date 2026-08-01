import Testing

@testable import PliersCommon

@Test func testBoolNot() {
	#expect(true.not == false)
	#expect(false.not == true)
}
