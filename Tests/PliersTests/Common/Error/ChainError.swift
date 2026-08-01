import Foundation
import Testing

@testable import PliersCommon

@Test func testContextCreatesChainWithRuntimeHead() {
	let base = NSError(domain: "d", code: 1)
	let chain = base.context("outer", file: "x.swift", line: 2, function: "f()")

	#expect(chain.chain.count == 2)
	#expect(chain.message == "outer")
	#expect(chain.description.contains("outer [x.swift:2 f()"))
}

@Test func testContextPrependsToExistingChain() {
	let base = NSError(domain: "d", code: 1)
	let first = base.context("first", file: "a.swift", line: 1, function: "a()")
	let second = first.context("second", file: "b.swift", line: 2, function: "b()")

	#expect(second.chain.count == 3)
	#expect(second.message == "second")
}

@Test func testResultContextAndExpect() {
	let failure: Result<Int, NSError> = .failure(NSError(domain: "x", code: 2))
	let wrapped = failure.context("failed", file: "z.swift", line: 5, function: "h()")

	switch wrapped {
	case .success:
		Issue.record("expected failure")
	case .failure(let error):
		#expect(error.message == "failed")
	}

	do {
		_ = try failure.expect("expected")
		Issue.record("expected throw")
	} catch let error as ChainError {
		#expect(error.message == "expected")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}
