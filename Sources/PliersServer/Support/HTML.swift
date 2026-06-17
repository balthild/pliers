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
	/// A namespace for Alpine.js attributes.
	/// See the [Alpine.js docs](https://alpinejs.dev) for more information.
	public enum x {}
}

extension HTMLAttribute.x {
	@inlinable
	public static func data(_ expr: String) -> HTMLAttribute {
		.init(name: "x-data", value: expr)
	}

	@inlinable
	public static func bind(_ name: String, _ expr: String) -> HTMLAttribute {
		.init(name: "x-bind:\(name)", value: expr)
	}

	@inlinable
	public static func on(_ event: String, _ expr: String) -> HTMLAttribute {
		.init(name: "x-on:\(event)", value: expr)
	}

	@inlinable
	public static func text(_ expr: String) -> HTMLAttribute {
		.init(name: "x-text", value: expr)
	}

	@inlinable
	public static func html(_ expr: String) -> HTMLAttribute {
		.init(name: "x-html", value: expr)
	}

	@inlinable
	public static func model(_ expr: String) -> HTMLAttribute {
		.init(name: "x-model", value: expr)
	}

	@inlinable
	public static func modelable(_ expr: String) -> HTMLAttribute {
		.init(name: "x-modelable", value: expr)
	}

	@inlinable
	public static func show(_ expr: String) -> HTMLAttribute {
		.init(name: "x-show", value: expr)
	}

	@inlinable
	public static func transition(_ expr: String) -> HTMLAttribute {
		.init(name: "x-transition", value: expr)
	}

	@inlinable
	public static func `for`(_ expr: String) -> HTMLAttribute {
		.init(name: "x-for", value: expr)
	}

	@inlinable
	public static func `if`(_ expr: String) -> HTMLAttribute {
		.init(name: "x-if", value: expr)
	}

	@inlinable
	public static func `init`(_ expr: String) -> HTMLAttribute {
		.init(name: "x-init", value: expr)
	}

	@inlinable
	public static func effect(_ expr: String) -> HTMLAttribute {
		.init(name: "x-effect", value: expr)
	}

	@inlinable
	public static func ref(_ expr: String) -> HTMLAttribute {
		.init(name: "x-ref", value: expr)
	}

	@inlinable
	public static func id(_ expr: String) -> HTMLAttribute {
		.init(name: "x-id", value: expr)
	}

	@inlinable
	public static func teleport(_ expr: String) -> HTMLAttribute {
		.init(name: "x-teleport", value: expr)
	}

	@inlinable
	public static var cloak: HTMLAttribute {
		.init(name: "x-cloak", value: nil)
	}

	@inlinable
	public static var ignore: HTMLAttribute {
		.init(name: "x-ignore", value: nil)
	}
}
