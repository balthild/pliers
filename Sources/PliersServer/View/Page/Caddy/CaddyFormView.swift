import Elementary

extension View.Page {
	struct CaddyFormView: HTML {
		let model: Caddy

		var body: some HTML {
			form(
				.method(.post),
				.when(model.id == nil) { .action("/caddy/create") },
				.when(model.id != nil) { .action("/caddy/\(model.id!)/update") },
				.class("form max-w-200 p-2 border border-gray-400"),
				.x.data(
					"""
					{
						tls: $history('\(model.config.tls.variant)'),
						backend: $history('\(model.config.backend.variant)')
					}
					"""),
			) {
				label(.class("field")) {
					span { "Domains" }
					textarea(.name("domains"), .required) {
						model.domains.joined(separator: "\n")
					}
				}

				hr()

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

				// TODO
				// fieldset(.x.if("tls == 'acme'"), .x.bind("disabled", "tls != 'acme'")) {}

				fieldset(.x.show("tls == 'file'"), .x.bind("disabled", "tls != 'file'")) {
					var cert = ""
					var key = ""
					if case .file(let _cert, let _key) = model.config.tls {
						let _ = cert = _cert
						let _ = key = _key
					}

					label(.class("field")) {
						span { "Cert" }
						input(
							.type(.text),
							.name("config[tls][file][cert]"),
							.value(cert),
							.required,
						)
					}

					label(.class("field")) {
						span { "Key" }
						input(
							.type(.text),
							.name("config[tls][file][key]"),
							.value(key),
							.required,
						)
					}
				}

				hr()

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

				fieldset(.x.show("backend == 'proxy'"), .x.bind("disabled", "backend != 'proxy'")) {
					var upstream = ""
					if case .proxy(let _upstream) = model.config.backend {
						let _ = upstream = _upstream
					}

					label(.class("field")) {
						span { "Upstream" }
						input(
							.type(.text),
							.name("config[backend][proxy][upstream]"),
							.value(upstream),
							.required,
						)
					}
				}

				fieldset(.x.show("backend == 'file'"), .x.bind("disabled", "backend != 'file'")) {
					var root = ""
					if case .file(let _root) = model.config.backend {
						let _ = root = _root
					}

					label(.class("field")) {
						span { "Root" }
						input(
							.type(.text),
							.name("config[backend][file][root]"),
							.value(root),
							.required,
						)
					}
				}

				fieldset(.x.show("backend == 'php'"), .x.bind("disabled", "backend != 'php'")) {
					var root = ""
					var fpm = ""
					if case .php(let _root, let _fpm) = model.config.backend {
						let _ = root = _root
						let _ = fpm = _fpm
					}

					label(.class("field")) {
						span { "Root" }
						input(
							.type(.text),
							.name("config[backend][php][root]"),
							.value(root),
							.required,
						)
					}

					label(.class("field")) {
						span { "FPM" }
						input(
							.type(.text),
							.name("config[backend][php][fpm]"),
							.value(fpm),
							.required,
						)
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
					button(.type(.submit), .class("primary")) {
						model.id == nil ? "Create" : "Update"
					}
				}
			}
		}
	}
}
