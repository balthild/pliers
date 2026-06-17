import Elementary

extension UI.Page {
	struct Login: HTMLDocument {
		var title: String { "Login" }

		var head: some HTML {
			UI.Component.CommonHead()
		}

		var body: some HTML {
			UI.Layout.Auth {
				div(.x.data("{ tab: 'passkey' }")) {
					header(.class("flex gap-3 mb-3 -mt-1")) {
						h2(.class("text-base font-bold grow")) { "Login" }

						button(
							.class("link"),
							.x.bind("class", "{ current: tab === 'passkey' }"),
							.x.on("click", "tab = 'passkey'"),
						) { "Passkey" }

						button(
							.class("link"),
							.x.bind("class", "{ current: tab === 'password' }"),
							.x.on("click", "tab = 'password'"),
						) { "Password" }

						button(
							.class("link"),
							.x.bind("class", "{ current: tab === 'token' }"),
							.x.on("click", "tab = 'token'"),
						) { "Token" }
					}

					main(.class("grow")) {
						div(.x.cloak, .x.show("tab === 'passkey'")) { passkey }
						div(.x.cloak, .x.show("tab === 'password'")) { password }
						div(.x.cloak, .x.show("tab === 'token'")) { token }
					}
				}
			}
		}

		@HTMLBuilder
		private var passkey: some HTML {
			div(.class("form")) {
				label(.class("field")) {
					span { "Passkey (TODO)" }
					button(.type(.button), .class("primary")) {
						"Login with Passkey"
					}
				}
			}
		}

		@HTMLBuilder
		private var password: some HTML {
			form(.method(.post), .action("/login/password"), .class("form")) {
				label(.class("field")) {
					span { "Username" }
					input(.name("username"), .type(.text), .required, .autocomplete("username"))
				}

				label(.class("field")) {
					span { "Password" }
					input(.name("password"), .type(.password), .required, .autocomplete("current-password"))
				}

				label(.class("field")) {
					span { "TOTP" }
					input(.name("totp"), .type(.password), .required, .autocomplete("one-time-code"))
				}

				div(.class("actions")) {
					button(.class("primary")) { "Login" }
				}
			}
		}

		@HTMLBuilder
		private var token: some HTML {
			form(.method(.post), .action("/login/token"), .class("form")) {
				p(.class("text-sm")) {
					"Run the "
					code { "pliers auth" }
					" command to get a temporary login token."
				}

				label(.class("field")) {
					span { "Token" }
					input(.name("token"), .type(.password), .required, .autocomplete(.off))
				}

				div(.class("actions")) {
					button(.class("primary")) { "Login" }
				}
			}
		}
	}
}
