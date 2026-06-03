import Foundation

public struct RuntimeError: Error {
	public let message: String
	public let file: String
	public let line: Int
	public let function: String

	public init(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) {
		self.message = message
		self.file = file
		self.line = line
		self.function = function
	}
}

extension RuntimeError: LocalizedError {
	public var errorDescription: String? {
		return "\(message) [\(file):\(line) \(function)]"
	}
}

extension Optional {
	public func expect(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) throws -> Wrapped {
		if let self {
			return self
		} else {
			throw RuntimeError(message, file: file, line: line, function: function)
		}
	}
}
