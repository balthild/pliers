import Elementary

extension View.Component {
	struct ArrayInput: HTML {
		let name: String
		let values: [String]

		var body: some HTML {
			div(.class("flex flex-col gap-2"), .x.data("{ values: \(values.quoteJSON) }")) {
				template(.x.for("(value, index) in values")) {
					div(.class("flex gap-2")) {
						input(
							.type(.text),
							.name(name),
							.class("grow"),
							// use index access to avoid losing reactivity
							.x.model("values[index]"),
						)
						button(.type(.button), .x.on("click", "values.splice(index, 1)")) {
							"Remove"
						}
					}
				}

				button(.type(.button), .x.on("click", "values.push('')")) {
					"Add"
				}
			}
		}
	}
}
