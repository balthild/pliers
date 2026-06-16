import Elementary
import Vapor

extension UI.Layout {
	struct Auth<Content: HTML>: HTML {
		@UI.Context var req: Request

		let content: Content

		init(@HTMLBuilder content: () -> Content) {
			self.content = content()
		}

		var body: some HTML {
			div(.class("flex-1 bg-gray-100")) {
				main(.class("w-full max-w-xl border border-gray-400 p-4 mt-24 mx-auto bg-white")) {
					content
				}
			}
		}
	}
}
