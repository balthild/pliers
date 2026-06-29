import Elementary
import PliersCommon
import Vapor

extension UI.Page {
	struct Settings: HTMLPage {
		@UI.Context var req: Request

		let layout = UI.Layout.Dashboard<Self>()

		var title: String { "Settings" }

		@HTMLBuilder
		func body() throws -> some HTML {
			h2 { title }
			hr()
			try passkey()
			hr()
			try password()
		}

		@HTMLBuilder
		private func passkey() throws -> some HTML {
			h3(.class("mb-1")) { "Passkey (TODO)" }

			table {
				thead {
					tr {
						th { "Name" }
						th { "Last Change" }
						th { "Last Use" }
						th { "Actions" }
					}
				}

				tbody {
					// TODO: passkey

					tr {
						td(.colspan(4), .class("text-center")) {
							button(.class("link")) { "Add Passkey" }
						}
					}
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
