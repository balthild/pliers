import Elementary
import Foundation

extension HTMLElement where Tag == HTMLTag.time, Content == HTMLText {
	public struct TimeRenderType: Sendable, Equatable {
		fileprivate let value: String

		public static var iso: Self { .init(value: "iso") }
		public static var full: Self { .init(value: "full") }
		public static var date: Self { .init(value: "date") }
		public static var time: Self { .init(value: "time") }
	}

	public static func render(_ date: Date, type: TimeRenderType = .full) -> Self {
		.render(date.ISO8601Format(), type: type)
	}

	public static func render(_ string: String, type: TimeRenderType = .full) -> Self {
		.init(.datetime(string), .data("render", type.value)) { string }
	}
}

extension HTMLElement where Tag == HTMLTag.fieldset {
	public static func when(_ expr: String, @HTMLBuilder content: () -> Content) -> Self {
		.init(
			.x.cloak,
			.x.show(expr),
			.x.bind("disabled", "!(\(expr))"),
			content: content,
		)
	}
}
