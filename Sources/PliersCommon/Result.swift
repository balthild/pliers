extension Result {
	@inline(always)
	public init(catching body: () async throws(Failure) -> Success) async {
		do {
			self = .success(try await body())
		} catch {
			self = .failure(error)
		}
	}

	public var success: Success? {
		switch self {
		case .success(let value):
			return value
		case .failure:
			return nil
		}
	}

	public var failure: Failure? {
		switch self {
		case .success:
			return nil
		case .failure(let error):
			return error
		}
	}
}
