import Elementary

extension View.Page {
	struct CronFormView: HTML {
		let model: Cron

		var body: some HTML {
			form(
				.method(.post),
				.when(model.id == nil) { .action("/cron/create") },
				.when(model.id != nil) { .action("/cron/\(model.id!)/update") },
				.class("form max-w-200 p-2 border border-gray-400"),
			) {
				label(.class("field")) {
					span { "Expression" }
					input(
						.type(.text),
						.name("expr"),
						.value(model.expr),
						.required,
						.placeholder("e.g. */5 * * * *"),
					)
				}

				p {
					"TODO: show explanation for the cron expression"
				}

				hr()

				label(.class("field")) {
					span { "Command" }
					textarea(.name("command"), .required) {
						model.command
					}
				}

				div(.class("actions")) {
					a(.href("/cron"), .class("btn")) { "Cancel" }
					button(.type(.submit), .class("primary")) { "Save" }
				}
			}
		}
	}
}
