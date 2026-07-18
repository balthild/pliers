import Elementary

extension HTMLAttribute {
	public func when(_ condition: Bool) -> Self {
		if condition {
			return self
		} else {
			return .init(name: "", value: nil)
		}
	}

	public static func when(_ condition: Bool, _ attribute: () -> Self) -> Self {
		if condition {
			return attribute()
		} else {
			return .init(name: "", value: nil)
		}
	}

	public static func custom(_ name: String) -> Self {
		.init(name: name, value: nil)
	}
}

// MARK: form

extension HTMLAttribute where Tag == HTMLTag.form {
	public struct EncType: Sendable, Equatable {
		fileprivate let value: String

		public static var multipartFormData: Self {
			.init(value: "multipart/form-data")
		}
	}

	public static func enctype(_ value: EncType) -> Self {
		.init(name: "enctype", value: value.value)
	}
}

// MARK: input

extension HTMLAttribute where Tag == HTMLTag.input {
	public static var readonly: Self {
		.init(name: "readonly", value: nil)
	}

	public static func pattern(_ value: String) -> HTMLAttribute {
		.init(name: "pattern", value: value)
	}
}

// MARK: textarea

extension HTMLAttribute where Tag == HTMLTag.textarea {
	public static func rows(_ value: Int) -> HTMLAttribute {
		.init(name: "rows", value: String(value))
	}

	public static func cols(_ value: Int) -> HTMLAttribute {
		.init(name: "cols", value: String(value))
	}
}

// MARK: td

extension HTMLAttribute where Tag == HTMLTag.td {
	public static func colspan(_ value: Int) -> Self {
		.init(name: "colspan", value: String(value))
	}

	public static func rowspan(_ value: Int) -> Self {
		.init(name: "rowspan", value: String(value))
	}
}

// MARK: dialog

extension HTMLAttribute where Tag == HTMLTag.dialog {
	public struct ClosedBy: Sendable, Equatable {
		fileprivate let value: String

		public static var none: Self { .init(value: "none") }
		public static var any: Self { .init(value: "any") }
		public static var closerequest: Self { .init(value: "closerequest") }
	}

	public static func closedby(_ value: ClosedBy) -> Self {
		.init(name: "closedby", value: value.value)
	}
}

// MARK: time

extension HTMLAttribute where Tag == HTMLTag.time {
	public static func datetime(_ value: String) -> Self {
		.init(name: "datetime", value: value)
	}
}
