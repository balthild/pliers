import Elementary
import PliersCommon

extension View.Page {
	struct PHPSettingsPage: HTMLPage {
		let model: PHP
		let status: String

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "PHP" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()
			View.Component.ServiceControl(
				status: status,
				prefix: "/php/\(model.version)/service",
			)
			hr()
			settings
		}

		@HTMLBuilder
		private var settings: some HTML {
			form(
				.method(.post),
				.action("/php/\(model.version)/update"),
				.class("form max-w-200 p-2 border border-gray-400"),
				.x.data(
					"""
					{
						listen: $history('\(model.config.listen.caseName)'),
					}
					"""
				),
			) {
				label(.class("field")) {
					span { "Version" }
					input(.type(.text), .value(model.version.string), .readonly)
				}

				hr()

				// MARK: listen

				div(.class("field")) {
					span { "Listen" }
					div(.class("flex gap-2")) {
						label(.class("radio")) {
							input(.type(.radio), .value("unix"), .x.model("listen"))
							"Unix Domain Socket"
						}

						label(.class("radio")) {
							input(.type(.radio), .value("tcp"), .x.model("listen"))
							"TCP"
						}
					}
				}

				p(.x.text("listen")) {}

				fieldset.when("listen == 'unix'") {
					label(.class("field")) {
						span { "Path" }
						input(
							.type(.text),
							.value(model.configurator.socket.string),
							.readonly,
						)
					}

					input(.type(.hidden), .name("config[listen][unix]"), .required)
				}

				fieldset.when("listen == 'tcp'") {
					let address = model.config.listen[case: \.tcp]

					label(.class("field")) {
						span { "Address" }
						input(
							.type(.text),
							.name("config[listen][tcp][_0]"),
							.value(address ?? "127.0.0.1:9000"),
							.required,
						)
					}
				}

				hr()

				// MARK: pool

				label(.class("field")) {
					span { "Process Manager" }
					select(.name("config[pm]"), .required) {
						option(.value("dynamic"), .selected.when(model.config.pm == .dynamic)) { "dynamic" }
						option(.value("static"), .selected.when(model.config.pm == .static)) { "static" }
						option(.value("ondemand"), .selected.when(model.config.pm == .ondemand)) {
							"ondemand"
						}
					}
				}

				label(.class("field")) {
					span { "Max Children" }
					input(
						.type(.number),
						.name("config[maxChildren]"),
						.value(String(model.config.maxChildren)),
						.min(1),
						.required,
					)
				}

				label(.class("field")) {
					span { "Start Servers" }
					input(
						.type(.number),
						.name("config[startServers]"),
						.value(String(model.config.startServers)),
						.min(1),
						.required,
					)
				}

				label(.class("field")) {
					span { "Min Spare Servers" }
					input(
						.type(.number),
						.name("config[minSpareServers]"),
						.value(String(model.config.minSpareServers)),
						.min(1),
						.required,
					)
				}

				label(.class("field")) {
					span { "Max Spare Servers" }
					input(
						.type(.number),
						.name("config[maxSpareServers]"),
						.value(String(model.config.maxSpareServers)),
						.min(1),
						.required,
					)
				}

				label(.class("field")) {
					span { "Max Requests" }
					input(
						.type(.number),
						.name("config[maxRequests]"),
						.value(String(model.config.maxRequests)),
						.min(0),
						.required,
					)
				}

				label(.class("field")) {
					span { "Terminate Timeout" }
					input(
						.type(.number),
						.name("config[terminateTimeout]"),
						.value(String(model.config.terminateTimeout)),
						.min(0),
						.required,
					)
				}

				hr()

				// MARK: ini

				label(.class("field")) {
					span { "Memory Limit" }
					input(
						.type(.text),
						.name("config[memoryLimit]"),
						.value(model.config.memoryLimit),
						.required,
					)
				}

				label(.class("field")) {
					span { "Upload Max Filesize" }
					input(
						.type(.text),
						.name("config[uploadMaxFilesize]"),
						.value(model.config.uploadMaxFilesize),
						.required,
					)
				}

				label(.class("field")) {
					span { "Post Max Size" }
					input(
						.type(.text),
						.name("config[postMaxSize]"),
						.value(model.config.postMaxSize),
						.required,
					)
				}

				label(.class("field")) {
					span { "Max Execution Time" }
					input(
						.type(.number),
						.name("config[maxExecutionTime]"),
						.value(String(model.config.maxExecutionTime)),
						.min(0),
						.required,
					)
				}

				div(.class("actions")) {
					a(.href("/php"), .class("btn")) { "Back" }
					button(.type(.submit), .class("primary")) { "Save" }
				}
			}
		}
	}
}
