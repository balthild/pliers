import Elementary
import Foundation
import Path
import Vapor

extension View.Page {
	struct PHPListPage: HTMLPage {
		typealias Available = (
			version: String,
			size: String,
			date: String,
		)

		let available: [Available]
		let installed: [Package]

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "PHP" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()
			dialogs
			actions
			packages
		}

		@HTMLBuilder
		private var dialogs: some HTML {
			// MARK: install_dialog

			Alpine.data(
				"install_dialog",
				"""
				() => ({
					path: '',

					show(path) {
						this.path = path;
						this.$root.showModal();
					},

					cancel() {
						this.path = '';
						this.$root.close();
					},
				})
				""",
			)

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("install_dialog"),
				.x.data("install_dialog"),
			) {
				header { "Install PHP" }

				main {
					form(.method(.post), .class("form"), .action("/php/install")) {
						label(.class("field")) {
							span { "Version" }
							select(.name("version")) {
								for version in available {
									option(.value(version.version)) { version.version }
								}
							}
						}

						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("primary")) { "Install" }
						}
					}
				}
			}

			// MARK: remove_dialog

			Alpine.data(
				"remove_dialog",
				"""
				() => ({
					version: '',

					get url() {
						if (!this.version) return '/404';
						return `/php/${this.version}/remove`
					},

					show(version) {
						this.version = version;
						this.$root.showModal();
					},

					cancel() {
						this.version = '';
						this.$root.close();
					},
				})
				""",
			)

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("remove_dialog"),
				.x.data("remove_dialog"),
			) {
				header { "Remove" }

				main {
					section(.class("mb-3 text-sm space-y-1")) {
						p {
							"Removing PHP "
							code(.x.text("version")) {}
							"."
						}
						p { "This action cannot be undone." }
					}

					form(
						.method(.post),
						.class("form"),
						.x.bind("action", "url"),
					) {
						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("danger")) { "Remove" }
						}
					}
				}
			}
		}

		@HTMLBuilder
		private var actions: some HTML {
			div(.class("flex gap-2 mb-2")) {
				button(.on(.click, "$('#install_dialog').show()")) { "Install" }
			}
		}

		@HTMLBuilder
		private var packages: some HTML {
			h3(.class("mb-1")) { "Installed" }

			table {
				thead {
					tr {
						th { "Version" }
						th { "Actions" }
					}
				}

				tbody {
					for package in installed {
						tr {
							td { package.version }
							td {
								button(
									.class("link text-red-700"),
									.on(.click, "$('#remove_dialog').show('\(package.version)');"),
								) { "Remove" }
							}
						}
					}

					if installed.isEmpty {
						tr {
							td(.colspan(3), .class("text-center text-gray-500")) {
								"No installed PHP versions."
							}
						}
					}
				}
			}
		}
	}
}
