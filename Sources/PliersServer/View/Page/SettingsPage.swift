import Elementary
import PliersCommon
import Vapor

extension View.Page {
	struct SettingsPage: HTMLPage {
		@View.Context var req: Request

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Settings" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()
			try passkey()
			hr()
			try password()
		}

		@HTMLBuilder
		private func passkey() throws -> some HTML {
			let user = try req.auth.require(User.self)

			h3(.class("mb-1")) { "Passkey" }

			table {
				thead {
					tr {
						th { "Name" }
						th { "Last Used" }
						th { "Actions" }
					}
				}

				tbody {
					for passkey in user.passkeys {
						tr {
							td { passkey.name }
							td {
								if let date = passkey.lastUsed {
									time(.datetime("\(date.ISO8601Format())")) {}
								}
							}
							td {
								div(.class("flex gap-2")) {
									let id = try passkey.requireID()
									let name = passkey.name

									button(
										.class("link"),
										.on(.click, "$('#passkey_rename_dialog').show('\(id)', \(name.quoteJSON));"),
									) { "Rename" }

									button(
										.class("link text-red-700"),
										.on(.click, "$('#passkey_delete_dialog').show('\(id)');"),
									) { "Delete" }
								}
							}
						}
					}

					script {
						HTMLRaw(
							"""
							const parent = document.currentScript.parentElement;
							parent.querySelectorAll('time').forEach((el) => {
								const date = new Date(el.dateTime);
								el.textContent = date.toLocaleString();
							});
							"""
						)
					}

					tr {
						td(.colspan(3), .class("text-center")) {
							button(.class("link"), .on(.click, "$('#passkey_new_dialog').show();")) {
								"New Passkey"
							}
						}
					}
				}
			}

			// MARK: passkey_rename_dialog

			Alpine.data(
				"passkey_rename_dialog",
				"""
				() => ({
					id: '',
					name: '',

					get url() {
						if (!this.id) return '/404';
						return `/settings/passkey/${this.id}/update`
					},

					show(id, name) {
						this.$root.showModal();
						this.id = id;
						this.name = name;
					},

					cancel() {
						this.id = '';
						this.name = '';
						this.$root.close();
					},
				})
				""",
			)

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("passkey_rename_dialog"),
				.x.data("passkey_rename_dialog"),
			) {
				header { "Rename Passkey" }

				main {
					form(
						.method(.post),
						.class("form"),
						.x.bind("action", "url"),
					) {
						label(.class("field")) {
							span { "Name" }
							input(
								.name("name"),
								.type(.text),
								.required,
								.x.model("name"),
								.autocomplete(.off),
								.custom("data-1p-ignore"),
							)
						}

						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("primary")) { "Save" }
						}
					}
				}
			}

			// MARK: passkey_delete_dialog

			Alpine.data(
				"passkey_delete_dialog",
				"""
				() => ({
					id: '',

					get url() {
						if (!this.id) return '/404';
						return `/settings/passkey/${this.id}/delete`
					},

					show(id) {
						this.$root.showModal();
						this.id = id;
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
				.id("passkey_delete_dialog"),
				.x.data("passkey_delete_dialog"),
			) {
				header { "Delete Passkey" }

				main {
					p(.class("mb-3 text-sm")) { "This action cannot be undone." }

					form(
						.method(.post),
						.class("form"),
						.x.bind("action", "url"),
					) {
						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("danger")) { "Delete" }
						}
					}
				}
			}

			// MARK: passkey_new_dialog

			Alpine.data(
				"passkey_new_dialog",
				"""
				() => ({
					open: false,
					error: '',
					name: '',

					show() {
						// cannot use modal dialog because it blocks 1password UI
						this.$root.show();
						this.open = true;
						this.error = '';
						this.name = '';
					},

					cancel() {
						this.open = false;
						this.error = '';
						this.name = '';
						this.$root.close();
					},

					async submit(event) {
						event.preventDefault();

						try {
							this.error = '';
							await passkeyCreate(this.name);
						} catch (error) {
							this.error = error.message ?? String(error);
						}
					},
				})
				""",
			)

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("passkey_new_dialog"),
				.x.data("passkey_new_dialog"),
				.x.trap("open"),
			) {
				header { "New Passkey" }

				main {
					p(
						.class("text-sm text-red-700 mb-3"),
						.x.cloak,
						.x.show("error"),
						.x.text("error"),
					) {}

					form(.class("form"), .x.on("submit", "submit")) {
						label(.class("field")) {
							span { "Name" }
							input(
								.name("name"),
								.type(.text),
								.required,
								.x.model("name"),
								.autocomplete(.off),
								.custom("data-1p-ignore"),
							)
						}

						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel()")) { "Cancel" }
							button(.type(.submit), .class("primary")) { "Create" }
						}
					}
				}

				template(.x.teleport("body")) {
					div(.class("dialog-backdrop"), .x.cloak, .x.show("open")) {}
				}
			}
		}

		@HTMLBuilder
		private func password() throws -> some HTML {
			h3(.class("mb-1")) { "Password" }

			let user = try req.auth.require(User.self)

			if user.password != nil && user.totp != nil {
				div(.x.data("{ step: 0 }")) {
					div(.class("flex gap-2"), .x.show("!step")) {
						button(.x.on("click", "step = 1")) { "Change" }

						form(.method(.post), .action("/settings/password/delete")) {
							button { "Remove" }
						}
					}

					form(
						.method(.post),
						.action("/settings/password/update"),
						.class("form max-w-100 p-2 border border-gray-400"),
						.x.cloak,
						.x.show("step"),
					) {
						label(.class("field"), .x.show("step === 1")) {
							span { "Username" }
							input(
								.name("username"),
								.type(.text),
								.value(user.username),
								.readonly,
							)
						}

						label(.class("field")) {
							span { "Password" }
							input(
								.name("password"),
								.type(.password),
								.required,
								.autocomplete("new-password"),
							)
						}

						label(.class("field")) {
							span { "Confirm" }
							input(
								.name("password_confirmation"),
								.type(.password),
								.required,
								.autocomplete("new-password"),
							)
						}

						div(.class("actions")) {
							button(.type(.button), .x.on("click", "step = 0")) { "Cancel" }
							button(.type(.submit), .class("primary")) { "Save" }
						}
					}
				}
			} else {
				div(.x.data("{ step: 0 }")) {
					button(.x.show("!step"), .x.on("click", "step = 1")) {
						"Create"
					}

					form(
						.method(.post),
						.action("/settings/password"),
						.class("form max-w-100 p-2 border border-gray-400"),
						.x.cloak,
						.x.show("step"),
					) {
						label(.class("field"), .x.show("step === 1")) {
							span { "Username" }
							input(
								.name("username"),
								.type(.text),
								.value(user.username),
								.readonly,
							)
						}

						label(.class("field"), .x.show("step === 1")) {
							span { "Password" }
							input(
								.name("password"),
								.type(.password),
								.required,
								.autocomplete("new-password"),
							)
						}

						label(.class("field"), .x.show("step === 1")) {
							span { "Confirm" }
							input(
								.name("password_confirmation"),
								.type(.password),
								.required,
								.autocomplete("new-password"),
							)
						}

						div(.class("actions"), .x.show("step === 1")) {
							button(.type(.button), .x.on("click", "step = 0")) { "Cancel" }
							button(.type(.button), .class("primary"), .x.on("click", "step = 2")) { "Next" }
						}

						div(.class("field"), .x.show("step === 2")) {
							span {}
							div(.class("max-w-50")) {
								let url = TOTPConfig().toURL()

								div(.id("totp-qr-code"), .class("border border-gray-500")) {}
								script(.type(.module)) {
									// the url should contain no backticks so I don't do a real escaping
									let clean = url.replacing("`", with: "")

									HTMLRaw(
										"""
										import { renderSVG } from 'https://esm.sh/uqr@0.1.3?exports=renderSVG';
										document.getElementById('totp-qr-code').innerHTML = renderSVG(`\(clean)`);
										"""
									)
								}

								input(
									.name("totp_config"),
									.type(.hidden),
									.value(url),
								)
							}
						}

						label(.class("field"), .x.show("step === 2")) {
							span { "TOTP" }
							input(
								.name("totp_code"),
								.type(.password),
								.required,
								.autocomplete("one-time-code"),
							)
						}

						div(.class("actions"), .x.show("step === 2")) {
							button(.type(.button), .x.on("click", "step = 1")) { "Back" }
							button(.type(.submit), .class("primary")) { "Save" }
						}
					}
				}
			}
		}
	}
}
