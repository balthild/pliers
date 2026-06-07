import Elementary

extension UI.Page.Auth {
	struct Login: HTMLDocument {
		var title: String { "Login" }

		var head: some HTML {
			style {
				"""
				form {
					display: inline-flex;
					flex-direction: column;
					gap: 0.5em;

					label {
						display: inline-flex;
						flex-direction: row;
						gap: 0.5em;
					}
				}
				"""
			}
		}

		var body: some HTML {
			h1 { "Login" }
			password
			token
		}

		@HTMLBuilder
		var password: some HTML {
			h2 { "Login with Password" }

			form(.method(.post), .action("/login/password")) {
				label {
					span { "Username" }
					input(.name("username"), .type(.text), .required)
				}

				label {
					span { "Password" }
					input(.name("password"), .type(.password), .required)
				}

				label {
					span { "TOTP" }
					input(.name("totp"), .type(.text), .required)
				}

				button(.type(.submit)) { "Login" }
			}
		}

		@HTMLBuilder
		var token: some HTML {
			h2 { "Login with Token" }

			form(.method(.post), .action("/login/token")) {
				label {
					span { "Username" }
					input(.name("username"), .type(.text), .required)
				}

				label {
					span { "Token" }
					input(.name("token"), .type(.text), .required)
				}

				button(.type(.submit)) { "Login" }
			}
		}
	}
}
