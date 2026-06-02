public struct RuntimeError: Error {
	public let message: String

	public init(_ message: String) {
		self.message = message
	}
}

extension Optional {
	public func expect(_ message: String) throws -> Wrapped {
		if let self {
			return self
		} else {
			throw RuntimeError(message)
		}
	}
}
