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
			div(.class("root dashboard")) {
				sidebar

				main(.class("p-4")) {
					content
				}
			}
		}

		@HTMLBuilder
		private var sidebar: some HTML {
			aside(.class("sidebar")) {
				h1(.class("panel logo")) { "Pliers" }

				section(.class("panel vstack gap-1")) {
					UI.Component.ErrorBoundary {
						let user = try req.auth.require(User.self)

						p(.class("my-0")) {
							user.username
							span(.class("mx-1 text-secondary")) { "@" }
							ProcessInfo.processInfo.hostName
						}
					}

					div(.class("hstack gap-2")) {
						NavLink(text: "Settings", path: "/settings")

						form(.method(.post), .action("/logout"), .class("d-inline")) {
							button(.class("link")) { "Logout" }
						}
					}
				}

				nav(.class("panel vstack gap-1")) {
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
				let active = req.url.path.starts(with: path)
				a(.href(path), .class("current").when(active)) {
					text
				}
			}
		}
	}
}
