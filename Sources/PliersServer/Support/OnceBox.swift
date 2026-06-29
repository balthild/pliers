import NIOConcurrencyHelpers

/// https://github.com/apple/swift-nio/issues/2910
struct OnceBox<T>: @unchecked Sendable {
	private let lock: NIOLockedValueBox<T?>

	init(_ value: sending T) {
		self.lock = .init(value)
	}

	func take() -> sending T? {
		return lock.withLockedValue {
			return $0.take()
		}
	}
}
