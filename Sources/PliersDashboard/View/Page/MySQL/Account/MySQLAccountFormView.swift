import Elementary

extension View.Page {
	struct MySQLAccountFormView: HTML {
		let model: MySQLAccount

		private var editing: Bool { model.id != nil }

		var body: some HTML {
			form(
				.method(.post),
				.when(model.id == nil) { .action("/mysql/account/create") },
				.when(model.id != nil) { .action("/mysql/account/\(model.id!)/update") },
				.class("form max-w-200 p-2 border border-gray-400"),
			) {
				label(.class("field")) {
					span { "Username" }
					input(
						.type(.text),
						.name("username"),
						.value(model.username),
						.required,
						.disabled.when(editing),
						.placeholder("app"),
					)
				}

				label(.class("field")) {
					span { "Host" }
					input(
						.type(.text),
						.name("host"),
						.value(model.host),
						.required,
						.disabled.when(editing),
						.list("mysql_hosts"),
					)
					datalist(.id("mysql_hosts")) {
						option(.value("localhost")) {}
						option(.value("%")) {}
					}
				}

				label(.class("field")) {
					span { "Password" }
					input(
						.type(.password),
						.name("password"),
						.required.when(!editing),
						.placeholder(editing ? "leave blank to keep current" : ""),
					)
				}

				div(.class("actions")) {
					a(.href("/mysql"), .class("btn")) { "Cancel" }
					button(.type(.submit), .class("primary")) { "Save" }
				}
			}
		}
	}
}
