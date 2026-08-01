import Foundation
import Testing

@testable import PliersCommon

@Test func testAlertErrorFromMessage() {
	let error = AlertError("bad", file: "a.swift", line: 3, function: "fn()")

	#expect(error.message == "bad")
	#expect(error.localizedDescription.contains("bad [a.swift:3 fn()]"))
}

@Test func testErrorAlertWrapsContext() {
	let base = NSError(domain: "d", code: 1)
	let alert = base.alert("outer", file: "x.swift", line: 4, function: "fx()")

	#expect(alert.message == "outer")
	#expect(alert.description.contains("outer [x.swift:4 fx()]"))
}

@Test func testOptionalAlertThrows() {
	let value: Int? = nil

	do {
		_ = try value.alert("missing", file: "v.swift", line: 8, function: "g()")
		Issue.record("expected throw")
	} catch let error as AlertError {
		#expect(error.message == "missing")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}

@Test func testResultAlertThrowsAlertError() {
	let result: Result<Int, NSError> = .failure(NSError(domain: "x", code: 3))

	do {
		_ = try result.alert("nope")
		Issue.record("expected throw")
	} catch let error as AlertError {
		#expect(error.message == "nope")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}
