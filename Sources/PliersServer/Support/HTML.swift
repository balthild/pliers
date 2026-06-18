import Elementary

extension HTMLAttribute {
	public func when(_ condition: Bool) -> Self {
		if condition {
			return self
		} else {
			return .init(name: "", value: nil)
		}
	}
}

extension HTMLAttribute where Tag == HTMLTag.input {
	public static var readonly: Self {
		.init(name: "readonly", value: nil)
	}
}

extension HTMLAttribute where Tag == HTMLTag.td {
	public static func colspan(_ value: Int) -> Self {
		.init(name: "colspan", value: String(value))
	}

	public static func rowspan(_ value: Int) -> Self {
		.init(name: "rowspan", value: String(value))
	}
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
	/// A namespace for Alpine.js attributes.
	/// See the [Alpine.js docs](https://alpinejs.dev) for more information.
	public enum x {}
}

extension HTMLAttribute.x {
	public static func data(_ expr: String) -> HTMLAttribute {
		.init(name: "x-data", value: expr)
	}

	public static func bind(_ name: String, _ expr: String) -> HTMLAttribute {
		.init(name: "x-bind:\(name)", value: expr)
	}

	public static func on(_ event: String, _ expr: String) -> HTMLAttribute {
		.init(name: "x-on:\(event)", value: expr)
	}

	public static func text(_ expr: String) -> HTMLAttribute {
		.init(name: "x-text", value: expr)
	}

	public static func html(_ expr: String) -> HTMLAttribute {
		.init(name: "x-html", value: expr)
	}

	public static func model(_ expr: String) -> HTMLAttribute {
		.init(name: "x-model", value: expr)
	}

	public static func modelable(_ expr: String) -> HTMLAttribute {
		.init(name: "x-modelable", value: expr)
	}

	public static func show(_ expr: String) -> HTMLAttribute {
		.init(name: "x-show", value: expr)
	}

	public static func transition(_ expr: String) -> HTMLAttribute {
		.init(name: "x-transition", value: expr)
	}

	public static func `init`(_ expr: String) -> HTMLAttribute {
		.init(name: "x-init", value: expr)
	}

	public static func effect(_ expr: String) -> HTMLAttribute {
		.init(name: "x-effect", value: expr)
	}

	public static func ref(_ expr: String) -> HTMLAttribute {
		.init(name: "x-ref", value: expr)
	}

	public static func id(_ expr: String) -> HTMLAttribute {
		.init(name: "x-id", value: expr)
	}

	public static var cloak: HTMLAttribute {
		.init(name: "x-cloak", value: nil)
	}

	public static var ignore: HTMLAttribute {
		.init(name: "x-ignore", value: nil)
	}
}

extension HTMLAttribute.x where Tag == HTMLTag.template {
	public static func `for`(_ expr: String) -> HTMLAttribute {
		.init(name: "x-for", value: expr)
	}

	public static func `if`(_ expr: String) -> HTMLAttribute {
		.init(name: "x-if", value: expr)
	}

	public static func teleport(_ expr: String) -> HTMLAttribute {
		.init(name: "x-teleport", value: expr)
	}
}
