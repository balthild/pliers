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
				.x.data("{ expr: \(model.expr.quoteJSON), explanation: null }"),
				.x.effect("explanation = explainCronExpr(expr)"),
			) {
				label(.class("field")) {
					span { "Expression" }
					input(
						.type(.text),
						.name("expr"),
						.value(model.expr),
						.required,
						.placeholder("e.g. */5 * * * *"),
						.x.model("expr"),
					)
				}

				label(.class("field")) {
					span { "Explanation" }
					section(.class("text-sm")) {
						template(.x.if("explanation === null")) {
							p(.class("text-red-700")) { "Invalid crontab expression" }
						}
						template(.x.if("explanation !== null")) {
							ul(.class("list-disc pl-3.5 space-y-1.5")) {
								template(.x.if("explanation.macro !== null")) {
									li {
										p {
											span(.class("font-medium")) { "Macro: " }
											code(.x.text("explanation.macro.value")) {}
											span { " → " }
											code(.x.text("explanation.macro.expanded")) {}
										}
										p(.x.text("explanation.macro.description")) {}
									}
								}

								template(.x.for("field in explanation.fields")) {
									li {
										p {
											span(.class("font-medium")) {
												span(.x.text("field.label")) {}
												": "
											}
											code(.x.text("field.value")) {}
										}
										template(.x.if("field.description === null")) {
											p(.class("text-red-700")) { "Invalid field value" }
										}
										template(.x.if("field.description !== null")) {
											p(.x.text("field.description")) {}
										}
									}
								}
							}
						}
					}
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
