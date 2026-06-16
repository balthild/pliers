import Elementary
import Vapor

extension UI.Layout {
	struct Dashboard<Content: HTML>: HTML {
		@UI.Context var req: Request

		let content: Content

		init(@HTMLBuilder content: () -> Content) {
			self.content = content()
		}

		var body: some HTML {
			div(.class("flex items-stretch flex-1")) {
				sidebar

				main(.class("px-4 py-3")) {
					content
				}
			}
		}

		@HTMLBuilder
		private var sidebar: some HTML {
			let cls = (
				panel: "py-2 px-3 border-b border-gray-300",
				logo: "text-lg font-bold bg-gray-100 text-gray-500",
			)

			aside(.class("w-64 border-r border-gray-300")) {
				h1(.class("\(cls.panel) \(cls.logo)")) { "Pliers" }

				section(.class("\(cls.panel)")) {
					UI.Component.ErrorBoundary {
						let user = try req.auth.require(User.self)

						p(.class("my-0")) {
							user.username
							span(.class("mx-1 text-gray-500")) { "@" }
							ProcessInfo.processInfo.hostName
						}
					}

					div(.class("flex gap-2")) {
						NavLink(text: "Settings", path: "/settings")

						form(.method(.post), .action("/logout"), .class("inline")) {
							button(.class("link")) { "Logout" }
						}
					}
				}

				nav(.class("\(cls.panel)")) {
					div { NavLink(text: "Overview", path: "/") }
					div { NavLink(text: "Files", path: "/files") }
					div { NavLink(text: "Caddy", path: "/caddy") }
					div { NavLink(text: "MySQL", path: "/mysql") }
					div { NavLink(text: "Cron", path: "/cron") }
				}
			}
		}

		private struct NavLink: HTML {
			@UI.Context var req: Request

			let text: String
			let path: String

			var body: some HTML {
				a(.href(path), .class("current").when(req.url.path == path)) {
					text
				}
			}
		}
	}
}
