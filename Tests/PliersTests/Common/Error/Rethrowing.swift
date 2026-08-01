import Foundation
import Testing

@testable import PliersCommon

@Test func testRethrowingContextWithChain() {
	do {
		try rethrowing(context: "outer") {
			throw NSError(domain: "inner", code: 1)
		}
		Issue.record("expected throw")
	} catch let error as ChainError {
		#expect(error.message == "outer")
		#expect(error.chain.count == 2)
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}

@Test func testRethrowingContextWithoutChain() {
	do {
		try rethrowing(context: "outer", chain: false) {
			throw NSError(domain: "inner", code: 1)
		}
		Issue.record("expected throw")
	} catch let error as RuntimeError {
		#expect(error.message == "outer")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}

@Test func testRethrowingAlertWithChain() {
	do {
		try rethrowing(alert: "outer") {
			throw NSError(domain: "inner", code: 1)
		}
		Issue.record("expected throw")
	} catch let error as AlertError {
		#expect(error.message == "outer")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}

@Test func testRethrowingAlertWithoutChain() {
	do {
		try rethrowing(alert: "outer", chain: false) {
			throw NSError(domain: "inner", code: 1)
		}
		Issue.record("expected throw")
	} catch let error as AlertError {
		#expect(error.message == "outer")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}
