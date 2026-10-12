import Elementary
import Foundation

extension View.Page {
	struct CronListPage: HTMLPage {
		let users: [UUID: User]
		let owner: User?
		let jobs: [Cron]

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Cron" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			div(.class("mb-2 flex gap-2")) {
				a(.class("btn"), .href("/cron/new")) { "New" }

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
						th { "Expression" }
						th { "Command" }
						th {}
					}
				}

				tbody {
					for job in jobs {
						tr {
							td { code { job.expr } }
							td { job.command }
							td {
								div(.class("flex gap-2")) {
									a(.href("/cron/\(try job.uuid)")) { "Edit" }

									button(
										.class("link text-red-700"),
										.on(.click, "$('#delete_dialog').show('\(try job.uuid)');"),
									) { "Delete" }
								}
							}
						}
					}

					if jobs.isEmpty {
						tr {
							td(.colspan(3), .class("text-center text-gray-500")) {
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
						return `/cron/${this.id}/delete`;
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
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("danger")) { "Delete" }
						}
					}
				}
			}
		}
	}
}
