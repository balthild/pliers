public protocol Default {
	static var defaultValue: Self { get }
}

extension Optional: Default {
	public static var defaultValue: Self { nil }
}

extension Bool: Default {
	public static var defaultValue: Self { false }
}

extension String: Default {
	public static var defaultValue: Self { "" }
}

extension Int: Default {
	public static var defaultValue: Self { 0 }
}

extension Double: Default {
	public static var defaultValue: Self { 0.0 }
}
