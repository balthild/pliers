import Elementary
import Foundation

extension View.Page {
	struct MySQLPage: HTMLPage {
		let status: String
		let users: [UUID: User]
		let owner: User?
		let databases: [MySQL]

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "MySQL" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			View.Component.ServiceControl(
				status: status,
				prefix: "/mysql/service",
			)

			hr()

			h3(.class("mb-2")) { "Databases" }

			div(.class("mb-2 flex gap-2")) {
				a(.class("btn"), .href("/mysql/new")) { "New" }

				if !users.isEmpty {
					select(.on(.change, "location.search = `?user=${this.value}`")) {
						for (id, user) in users {
							option(
								.value("\(id)"),
								.selected.when(owner?.id == id),
							) { user.username }
						}
					}
				}
			}

			// MARK: table

			table {
				thead {
					tr {
						th { "Database" }
						th { "User" }
						th { "Host" }
						th {}
					}
				}

				tbody {
					for db in databases {
						tr {
							td { db.database }
							td { db.username }
							td { db.host }
							td {
								div(.class("flex gap-2")) {
									a(.href("/mysql/\(try db.uuid)")) { "Edit" }

									button(
										.class("link text-red-700"),
										.on(.click, "$('#delete_dialog').show('\(try db.uuid)');"),
									) { "Delete" }
								}
							}
						}
					}

					if databases.isEmpty {
						tr {
							td(.colspan(4), .class("text-center text-gray-500")) {
								"No data."
							}
						}
					}
				}
			}

			// MARK: delete_dialog

			Alpine.data(
				"delete_dialog",
				"""
				() => ({
					id: '',

					get url() {
						if (!this.id) return '/404';
						return `/mysql/${this.id}/delete`;
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
						p {
							"This drops the database and its user on the server, and cannot be undone. Type the id below to confirm."
						}
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
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("danger")) { "Delete" }
						}
					}
				}
			}
		}
	}
}
