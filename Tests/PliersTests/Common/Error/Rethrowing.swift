import Foundation
import Testing

@testable import PliersCommon

@Test func testRethrowingContextWithChain() {
	do {
		_ =
			try rethrowing(
				context: "outer",
				catching: {
					throw NSError(domain: "d", code: 1)
				},
			) as Int
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
		_ =
			try rethrowing(
				context: "outer",
				chain: false,
				catching: {
					throw NSError(domain: "d", code: 1)
				},
			) as Int
		Issue.record("expected throw")
	} catch let error as RuntimeError {
		#expect(error.message == "outer")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}

@Test func testRethrowingAlertWithChain() {
	do {
		_ =
			try rethrowing(
				alert: "outer",
				catching: {
					throw NSError(domain: "d", code: 1)
				},
			) as Int
		Issue.record("expected throw")
	} catch let error as AlertError {
		#expect(error.message == "outer")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}

@Test func testRethrowingAlertWithoutChain() {
	do {
		_ =
			try rethrowing(
				alert: "outer",
				chain: false,
				catching: {
					throw NSError(domain: "d", code: 1)
				},
			) as Int
		Issue.record("expected throw")
	} catch let error as AlertError {
		#expect(error.message == "outer")
	} catch {
		Issue.record("unexpected error: \(error)")
	}
}
