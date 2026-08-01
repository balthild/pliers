import Elementary

extension View.Page {
	struct LoginPage: HTMLPage {
		let layout = View.Layout.AuthLayout<Self>()

		var title: String { "Login" }

		@HTMLBuilder
		func body() -> sending some HTML {
			div(.x.data("{ tab: 'passkey' }")) {
				header(.class("flex gap-3 mb-3 -mt-1")) {
					h2(.class("text-base font-bold grow")) { title }

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

		@HTMLBuilder
		private var passkey: some HTML {
			Alpine.data(
				"passkey_login_form",
				"""
				() => ({
					error: '',

					async submit(event) {
						event.preventDefault();

						try {
							this.error = '';
							await passkeyLogin();
						} catch (error) {
							this.error = error.message ?? String(error);
						}
					},
				})
				""",
			)

			form(.class("form"), .x.data("passkey_login_form"), .x.on("submit", "submit")) {
				p(
					.class("text-sm text-red-700"),
					.x.cloak,
					.x.show("error"),
					.x.text("error"),
				) {}

				label(.class("field")) {
					span { "Passkey" }
					button(.type(.submit), .class("primary")) {
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
