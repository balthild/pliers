@inline(always)
public func rethrowing<T>(
	context message: String,
	chain: Bool = true,
	file: String = #file,
	line: Int = #line,
	function: String = #function,
	catching body: () throws -> T,
) throws -> T {
	do {
		return try body()
	} catch {
		if chain {
			throw error.context(message, file: file, line: line, function: function)
		} else {
			throw RuntimeError(message, file: file, line: line, function: function)
		}
	}
}

@inline(always)
public func rethrowing<T>(
	alert message: String,
	chain: Bool = true,
	file: String = #file,
	line: Int = #line,
	function: String = #function,
	catching body: () throws -> T,
) throws -> T {
	do {
		return try body()
	} catch {
		if chain {
			throw error.alert(message, file: file, line: line, function: function)
		} else {
			throw AlertError(message, file: file, line: line, function: function)
		}
	}
}
