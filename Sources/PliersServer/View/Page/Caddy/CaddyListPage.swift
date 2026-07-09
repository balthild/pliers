import Elementary
import Foundation
import Path
import Vapor

extension View.Page {
	struct CaddyListPage: HTMLPage {
		let sites: [Caddy]
		let status: String

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Caddy" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			div(.class("text-sm mb-2 flex gap-1.5 items-center")) {
				span(
					.class("size-1.75 rounded-full"),
					.class("bg-green-600").when(status == "active"),
					.class("bg-red-600").when(status == "inactive"),
					.class("bg-yellow-600").when(status != "active" && status != "inactive"),
				) {}

				span { status.capitalized }

				// a dummy button to prevent layout shift
				span(.class("btn text-xs px-0 w-0 invisible")) { "#" }

				if status == "active" {
					form(.method(.post), .action("/caddy/service/stop")) {
						button(.type(.submit), .class("danger text-xs")) { "Stop" }
					}
					form(.method(.post), .action("/caddy/service/restart")) {
						button(.type(.submit), .class("text-xs")) { "Restart" }
					}
					form(.method(.post), .action("/caddy/service/reload")) {
						button(.type(.submit), .class("text-xs")) { "Reload" }
					}
				}

				if status == "inactive" {
					form(.method(.post), .action("/caddy/service/start")) {
						button(.type(.submit), .class("success text-xs")) { "Start" }
					}
				}
			}

			hr()

			h3(.class("mb-2")) { "Sites" }

			div(.class("mb-2 flex gap-2")) {
				a(.class("btn"), .href("/caddy/new")) { "New" }

				form(.method(.post), .action("/caddy/config/apply")) {
					button(.type(.submit)) { "Apply" }
				}
			}

			table {
				thead {
					tr {
						th { "Name" }
						th { "TLS" }
						th { "Backend" }
						th {}
					}
				}

				tbody {
					for site in sites {
						tr {
							td {
								for domain in site.domains {
									p { domain }
								}
							}
							td {
								switch site.config.tls {
								case .some(.acme): "ACME"
								case .some(.file): "Custom"
								case .none: ""
								}
							}
							td {
								switch site.config.backend {
								case .some(.proxy): "Proxy"
								case .some(.file): "File"
								case .some(.php): "PHP"
								case .none: ""
								}
							}
							td {
								div(.class("flex gap-2")) {
									a(.href("/caddy/\(try site.requireID())")) { "Edit" }

									button(
										.class("link text-red-700"),
										.x.data(),
										.x.on(
											"click",
											"""
											const app = Alpine.$data(window.delete_dialog);
											app.show('\(try site.requireID())');
											""",
										),
									) { "Delete" }
								}
							}
						}
					}

					if sites.isEmpty {
						tr {
							td(.colspan(4), .class("text-center text-gray-500")) {
								"No data."
							}
						}
					}
				}
			}

			Alpine.data(
				"delete_dialog",
				"""
				() => ({
					id: '',

					get url() {
						if (!this.id) return '/404';
						return `/caddy/${this.id}/delete`;
					},

					show(id) {
						this.id = id;
						this.$root.showModal();
					},

					cancel() {
						this.id = '';
						this.$root.close();
					},
				})
				""",
			)

			dialog(.closedby(.none), .class("w-100"), .id("delete_dialog"), .x.data("delete_dialog")) {
				header { "Delete" }

				main {
					section(.class("mb-3 text-sm space-y-1")) {
						p {
							"Deleting "
							code(.x.text("id")) {}
						}
						p { "This action cannot be undone. Type the id below to confirm." }
					}

					form(
						.method(.post),
						.class("form"),
						.x.bind("action", "url"),
					) {
						label(.class("field")) {
							span { "ID" }
							input(
								.name("confirm"),
								.type(.text),
								.required,
							)
						}

						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel()")) { "Cancel" }
							button(.type(.submit), .class("danger")) { "Delete" }
						}
					}
				}
			}
		}
	}
}
