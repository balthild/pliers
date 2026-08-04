extension Optional {
	@inline(__always)
	public func mapAsync<T>(_ transform: (Wrapped) async throws -> T) async rethrows -> T? {
		switch self {
		case .some(let value):
			return try await transform(value)
		case .none:
			return nil
		}
	}

	@inline(__always)
	public func flatMapAsync<T>(_ transform: (Wrapped) async throws -> T?) async rethrows -> T? {
		switch self {
		case .some(let value):
			return try await transform(value)
		case .none:
			return nil
		}
	}
}
