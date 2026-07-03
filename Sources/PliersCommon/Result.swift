extension Result {
	@inlinable
	public init(catching body: () async throws(Failure) -> Success) async {
		do {
			self = .success(try await body())
		} catch {
			self = .failure(error)
		}
	}
}
