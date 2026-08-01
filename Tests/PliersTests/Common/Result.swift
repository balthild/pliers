import Testing

@testable import PliersCommon

@Test func testAsyncResultCatchingSuccess() async {
	let result = await Result { () async throws in 42 }

	switch result {
	case .success(let value):
		#expect(value == 42)
	case .failure:
		Issue.record("expected success")
	}
}

@Test func testAsyncResultCatchingFailure() async {
	let result = await Result { () async throws in
		throw RuntimeError("boom")
	}

	switch result {
	case .failure(let error as RuntimeError):
		#expect(error.message == "boom")
	case .failure:
		Issue.record("expected RuntimeError")
	case .success:
		Issue.record("expected failure")
	}
}
