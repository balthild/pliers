import Elementary

extension View.Page {
	struct CaddyFormView: HTML {
		let model: Caddy
		let phps: [PHP]

		var body: some HTML {
			form(
				.method(.post),
				.when(model.id == nil) { .action("/caddy/create") },
				.when(model.id != nil) { .action("/caddy/\(model.id!)/update") },
				.class("form max-w-200 p-2 border border-gray-400"),
				.x.data(
					"""
					{
						tls: $history('\(model.config.tls?.caseName ?? "")'),
						backend: $history('\(model.config.backend?.caseName ?? "")'),
					}
					"""
				),
			) {
				label(.class("field")) {
					span { "Domains" }
					textarea(.name("domains"), .required) {
						model.domains.joined(separator: "\n")
					}
				}

				hr()

				// MARK: tls

				div(.class("field")) {
					span { "TLS" }
					div(.class("flex gap-2")) {
						label(.class("radio")) {
							input(.type(.radio), .value(""), .x.model("tls"))
							"None"
						}

						label(.class("radio")) {
							input(.type(.radio), .value("acme"), .x.model("tls"))
							"ACME"
						}

						label(.class("radio")) {
							input(.type(.radio), .value("file"), .x.model("tls"))
							"File"
						}
					}
				}

				fieldset.when("tls === 'acme'") {
					input(
						.type(.hidden),
						.name("config[tls][acme]"),
						.required,
					)
				}

				fieldset.when("tls === 'file'") {
					let file = model.config.tls?[case: \.file]

					label(.class("field")) {
						span { "Cert" }
						input(
							.type(.text),
							.name("config[tls][file][_0][cert]"),
							.value(file?.cert ?? ""),
							.required,
						)
					}

					label(.class("field")) {
						span { "Key" }
						input(
							.type(.text),
							.name("config[tls][file][_0][key]"),
							.value(file?.key ?? ""),
							.required,
						)
					}
				}

				hr()

				// MARK: backend

				div(.class("field")) {
					span { "Backend" }
					div(.class("flex gap-2")) {
						label(.class("radio")) {
							input(.type(.radio), .value(""), .x.model("backend"))
							"None"
						}

						label(.class("radio")) {
							input(.type(.radio), .value("proxy"), .x.model("backend"))
							"Proxy"
						}

						label(.class("radio")) {
							input(.type(.radio), .value("file"), .x.model("backend"))
							"File"
						}

						label(.class("radio")) {
							input(.type(.radio), .value("php"), .x.model("backend"))
							"PHP"
						}
					}
				}

				fieldset.when("backend === 'proxy'") {
					let proxy = model.config.backend?[case: \.proxy]

					label(.class("field")) {
						span { "Upstream" }
						input(
							.type(.text),
							.name("config[backend][proxy][_0][upstream]"),
							.value(proxy?.upstream ?? ""),
							.required,
						)
					}
				}

				fieldset.when("backend === 'file'") {
					let file = model.config.backend?[case: \.file]

					label(.class("field")) {
						span { "Root" }
						input(
							.type(.text),
							.name("config[backend][file][_0][root]"),
							.value(file?.root ?? model.candidateWebRoot),
							.placeholder("Leave blank to use the default path"),
						)
					}
				}

				fieldset.when("backend === 'php'") {
					let php = model.config.backend?[case: \.php]

					label(.class("field")) {
						span { "Root" }
						input(
							.type(.text),
							.name("config[backend][php][_0][root]"),
							.value(php?.root ?? model.candidateWebRoot),
							.placeholder("Leave blank to use the default path"),
						)
					}

					label(.class("field")) {
						span { "Address" }
						div(.class("flex gap-2")) {
							input(
								.type(.text),
								.name("config[backend][php][_0][fpm]"),
								.value(php?.fpm ?? ""),
								.required,
								.class("grow"),
								.x.ref("fpm"),
							)

							select(
								.class("btn bg-none"),
								.x.on(
									"change",
									"""
									const value = $event.target.value;
									if (value) $refs.fpm.value = value;
									$event.target.selectedIndex = 0;
									""",
								),
							) {
								option(.value("")) { "Choose" }
								for php in phps {
									let address = php.config.caddyListenAddress(version: php.version)
									option(.value(address)) { php.version.string }
								}
							}
						}
					}
				}

				hr()

				label(.class("field")) {
					span { "Custom" }
					textarea(.name("config[custom]"), .class("font-mono")) {
						model.config.custom
					}
				}

				div(.class("actions")) {
					a(.href("/caddy"), .class("btn")) { "Cancel" }
					button(.type(.submit), .class("primary")) { "Save" }
				}
			}
		}
	}
}
