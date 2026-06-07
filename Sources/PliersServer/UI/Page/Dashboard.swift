import Elementary

extension UI.Page {
	struct Dashboard: HTMLDocument {
		let user: User

		var title: String { "Dashboard" }

		var head: some HTML {}

		var body: some HTML {
			h1 { "Hello, \(user.username)" }
			form(.method(.post), .action("/logout")) {
				button(.type(.submit)) { "Logout" }
			}
		}
	}
}
