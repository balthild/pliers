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
			div(.class("root auth")) {
				main(.class("main")) {
					content
				}
			}
		}
	}
}
