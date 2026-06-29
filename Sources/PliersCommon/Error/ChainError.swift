import Foundation

public struct ChainError: Error {
	public let chain: [Error]

	fileprivate init(_ chain: [Error]) {
		precondition(!chain.isEmpty, "ChainError must have at least one error")
		self.chain = chain
	}

	public var message: String {
		let head = chain[0]
		if let head = head as? RuntimeError {
			return head.message
		} else {
			return String(describing: head)
		}
	}
}

extension ChainError: CustomStringConvertible {
	public var description: String {
		return chain.map { $0.localizedDescription }.joined(separator: "\n--> ")
	}
}

extension ChainError: LocalizedError {
	public var errorDescription: String? {
		return description
	}
}

extension Error {
	public func context(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) -> ChainError {
		let head = RuntimeError(message, file: file, line: line, function: function)

		if let error = self as? ChainError {
			return ChainError([head] + error.chain)
		} else {
			return ChainError([head, self])
		}
	}
}

extension Result {
	public func context(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) -> Result<Success, ChainError> {
		self.mapError { $0.context(message, file: file, line: line, function: function) }
	}

	public func expect(
		_ message: String,
		file: String = #file,
		line: Int = #line,
		function: String = #function,
	) throws -> Success {
		try self.context(message, file: file, line: line, function: function).get()
	}
}
