import Elementary
import Path

extension View.Page {
	struct FileEditPage: HTMLPage, FileViewMixin {
		let path: Path
		let text: String

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Filesystem" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			p(.class("text-sm mb-2")) {
				"Editing File: "
				code { path.string }
			}

			form(
				.method(.post),
				.action(link(to: path, action: "update")),
				.class("form max-w-200 p-2 border border-gray-400"),
			) {
				label(.class("field")) {
					span { "Content" }
					textarea(
						.name("content"),
						.rows(30),
						.class("font-mono"),
					) { text }
				}

				div(.class("actions")) {
					a(.href(link(to: path.parent)), .class("btn")) { "Cancel" }
					button(.type(.submit), .class("primary")) { "Save" }
				}
			}
		}
	}
}
