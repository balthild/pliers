import Testing

@testable import PliersCommon

@Test func testRuntimeErrorDescription() {
	let error = RuntimeError("boom", file: "file.swift", line: 11, function: "fn()")

	#expect(error.message == "boom")
	#expect(error.description == "boom [file.swift:11 fn()]")
	#expect(error.errorDescription == error.description)
}

@Test func testOptionalExpect() {
	let value: Int? = 7
	#expect((try? value.expect("missing")) == 7)
}

@Test func testOptionalExpectThrowsRuntimeError() {
	let value: Int? = nil

	do {
		_ = try value.expect("missing", file: "f.swift", line: 9, function: "g()")
		Issue.record("expected throw")
	} catch let error as RuntimeError {
		#expect(error.message == "missing")
		#expect(error.file == "f.swift")
		#expect(error.line == 9)
		#expect(error.function == "g()")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}
