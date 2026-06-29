import Elementary
import PliersCommon
import Vapor

extension UI.Layout {
	struct Dashboard<Page: HTMLPage>: HTMLLayout {
		typealias Page = Page

		@UI.Context var req: Request

		func title(_ page: borrowing Page) -> String {
			return "\(page.title) - Pliers"
		}

		@HTMLBuilder
		func error(_ error: Swift.Error) -> some HTML {
			UI.Page.Error(error: error)
		}

		@HTMLBuilder
		func head(_ page: borrowing Page) throws -> some HTML {
			UI.Component.CommonHead()
			try page.head()
		}

		@HTMLBuilder
		func body(_ page: borrowing Page) throws -> some HTML {
			let body = try page.body()

			div(.class("flex items-stretch grow")) {
				sidebar

				main(.class("px-4 py-3 grow")) {
					body
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
					let user = try req.auth.require(User.self)

					p(.class("my-0")) {
						user.username
						span(.class("mx-1 text-gray-500")) { "@" }
						ProcessInfo.processInfo.hostName
					}

					div(.class("flex gap-2")) {
						link(text: "Settings", path: "/settings")

						form(.method(.post), .action("/logout")) {
							button(.class("link")) { "Logout" }
						}
					}
				}

				nav(.class("\(cls.panel)")) {
					div { link(text: "Overview", path: "/") }
					div { link(text: "Filesystem", path: "/file") }
					div { link(text: "Caddy", path: "/caddy") }
					div { link(text: "MySQL", path: "/mysql") }
					div { link(text: "Cron", path: "/cron") }
				}
			}
		}

		@HTMLBuilder
		private func link(text: String, path: String) -> some HTML {
			a(.href(path), .class("current").when(req.url.path == path)) {
				text
			}
		}
	}
}
