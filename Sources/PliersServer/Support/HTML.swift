import Elementary

extension HTMLAttribute {
	@inlinable
	public func when(_ condition: Bool) -> Self {
		if condition {
			return self
		} else {
			return .init(name: "", value: nil)
		}
	}
}

extension HTMLAttribute {
	@inlinable
	public static var xCloak: Self {
		.init(name: "x-cloak", value: nil)
	}

	@inlinable
	public static func xData(_ value: String) -> Self {
		.init(name: "x-data", value: value)
	}

	@inlinable
	public static func xBind(_ name: String, _ value: String) -> Self {
		.init(name: "x-bind:\(name)", value: value)
	}

	@inlinable
	public static func xOn(_ event: String, _ value: String) -> Self {
		.init(name: "x-on:\(event)", value: value)
	}

	@inlinable
	public static func xShow(_ value: String) -> Self {
		.init(name: "x-show", value: value)
	}
}
