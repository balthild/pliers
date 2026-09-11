extension Optional {
	@inline(always)
	public func mapAsync<T>(_ transform: (Wrapped) async throws -> T) async rethrows -> T? {
		switch self {
		case .some(let value):
			return try await transform(value)
		case .none:
			return nil
		}
	}

	@inline(always)
	public func flatMapAsync<T>(_ transform: (Wrapped) async throws -> T?) async rethrows -> T? {
		switch self {
		case .some(let value):
			return try await transform(value)
		case .none:
			return nil
		}
	}

	@inline(always)
	public func unwrapOr(_ fallback: Wrapped) -> Wrapped {
		switch self {
		case .some(let value):
			return value
		case .none:
			return fallback
		}
	}

	@inline(always)
	public func unwrapOrElse(_ fallback: () -> Wrapped) -> Wrapped {
		switch self {
		case .some(let value):
			return value
		case .none:
			return fallback()
		}
	}
}
