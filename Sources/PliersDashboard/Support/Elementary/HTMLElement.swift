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

	public init(_ date: Date, render: TimeRenderType = .full) {
		self.init(date.ISO8601Format(), render: render)
	}

	public init(_ string: String, render: TimeRenderType = .full) {
		self.init(.datetime(string), .data("render", render.value)) { string }
	}
}
