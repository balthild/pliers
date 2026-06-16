import Elementary

extension UI.Page {
	struct Login: HTMLDocument {
		var title: String { "Login" }

		var head: some HTML {
			UI.Component.CommonHead()
		}

		var body: some HTML {
			UI.Layout.Auth {
				div(.xData("{ tab: 'passkey' }")) {
					header(.class("hstack gap-2 mb-3")) {
						h2(.class("my-0 fs-6 flex-grow-1")) { "Login" }

						button(
							.class("link"),
							.xBind("class", "{ current: tab === 'passkey' }"),
							.xOn("click", "tab = 'passkey'"),
						) { "Passkey" }

						button(
							.class("link"),
							.xBind("class", "{ current: tab === 'password' }"),
							.xOn("click", "tab = 'password'"),
						) { "Password" }

						button(
							.class("link"),
							.xBind("class", "{ current: tab === 'token' }"),
							.xOn("click", "tab = 'token'"),
						) { "Token" }
					}

					main(.class("flex-grow-1")) {
						div(.xCloak, .xShow("tab === 'password'")) { password }
						div(.xCloak, .xShow("tab === 'token'")) { token }
					}
				}
			}
		}

		@HTMLBuilder
		private var password: some HTML {
			form(.method(.post), .action("/login/password"), .class("form")) {
				label(.class("field")) {
					span { "Username" }
					input(.name("username"), .type(.text), .required)
				}

				label(.class("field")) {
					span { "Password" }
					input(.name("password"), .type(.password), .required)
				}

				label(.class("field")) {
					span { "TOTP" }
					input(.name("totp"), .type(.password), .required)
				}

				div(.class("actions")) {
					button { "Login" }
				}
			}
		}

		@HTMLBuilder
		private var token: some HTML {
			form(.method(.post), .action("/login/token"), .class("form")) {
				label(.class("field")) {
					span { "Token" }
					input(.name("token"), .type(.password), .required)
				}

				div(.class("actions")) {
					button { "Login" }
				}
			}
		}
	}
}
