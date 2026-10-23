import Elementary
import Foundation

extension View.Page {
	struct MySQLPage: HTMLPage {
		let status: String
		let users: [UUID: User]
		let owner: User?
		let accounts: [MySQLAccount]

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

			h3(.class("mb-2")) { "Accounts" }

			actions
			accountsTable
			deleteDialog
		}

		@HTMLBuilder
		private var actions: some HTML {
			div(.class("mb-2 flex gap-2")) {
				a(.class("btn"), .href("/mysql/account/new")) { "New" }

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
		}

		// MARK: table

		@HTMLBuilder
		private var accountsTable: some HTML {
			table {
				thead {
					tr {
						th { "User" }
						th { "Host" }
						th {}
					}
				}

				tbody {
					for account in accounts {
						tr {
							td { account.username }
							td { account.host }
							td {
								div(.class("flex gap-2")) {
									a(.href("/mysql/account/\(try account.uuid)")) { "Edit" }

									button(
										.class("link text-red-700"),
										.on(.click, "$('#delete_account_dialog').show('\(try account.uuid)');"),
									) { "Delete" }
								}
							}
						}
					}

					if accounts.isEmpty {
						tr {
							td(.colspan(3), .class("text-center text-gray-500")) {
								"No data."
							}
						}
					}
				}
			}
		}

		// MARK: delete_account_dialog

		@HTMLBuilder
		private var deleteDialog: some HTML {
			Alpine.data(
				"delete_account_dialog",
				"""
				() => ({
					id: '',

					get url() {
						if (!this.id) return '/404';
						return `/mysql/account/${this.id}/delete`;
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

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("delete_account_dialog"),
				.x.data("delete_account_dialog"),
			) {
				header { "Delete" }

				main {
					section(.class("mb-3 text-sm space-y-1")) {
						p {
							"Deleting "
							code(.x.text("id")) {}
						}
						p {
							"This drops the MySQL account on the server and cannot be undone. Type the id below to confirm."
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
