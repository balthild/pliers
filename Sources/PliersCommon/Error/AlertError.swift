import Foundation

public struct AlertError: Error {
	let inner: Error

	fileprivate init(inner: Error) {
		self.inner = inner
	}

	public init(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) {
		self.inner = RuntimeError(message, file: file, line: line, function: function)
	}

	public var message: String {
		switch inner {
		case let inner as RuntimeError:
			return inner.message
		case let inner as ChainError:
			return inner.message
		default:
			return String(describing: inner)
		}
	}
}

extension AlertError: CustomStringConvertible {
	public var description: String {
		return String(describing: inner)
	}
}

extension AlertError: LocalizedError {
	public var errorDescription: String? {
		return inner.localizedDescription
	}
}

extension Error {
	public func alert(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) -> AlertError {
		if let error = self as? AlertError {
			return error.inner.alert(message, file: file, line: line, function: function)
		}

		let inner = self.context(message, file: file, line: line, function: function)
		return AlertError(inner: inner)
	}
}

extension Optional {
	public func alert(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) throws -> Wrapped {
		if let self {
			return self
		} else {
			let inner = RuntimeError(message, file: file, line: line, function: function)
			throw AlertError(inner: inner)
		}
	}
}

extension Result {
	public func alert(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) throws -> Success {
		try self.mapError { $0.alert(message, file: file, line: line, function: function) }.get()
	}
}
