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
						compression: {
							enable: \(model.config.compression.enable),
							customize: \(model.config.compression.customize),
							gzipEnable: \(model.config.compression.gzipEnable),
							zstdEnable: \(model.config.compression.zstdEnable),
						},
						cache: {
							enable: \(model.config.cache.enable),
						},
						cors: {
							enable: \(model.config.cors.enable),
						},
						logging: {
							enable: \(model.config.logging.enable),
						},
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

					div(.class("field")) {
						span { "Trusted Proxies" }
						div(.class("flex gap-2")) {
							label(.class("checkbox")) {
								input.checkbox(
									type: .boolean,
									name: "config[trustedProxies][docker]",
									.checked.when(model.config.trustedProxies.docker),
								)
								"Docker Network"
							}

							label(.class("checkbox")) {
								input.checkbox(
									type: .boolean,
									name: "config[trustedProxies][cloudflare]",
									.checked.when(model.config.trustedProxies.cloudflare),
								)
								"Cloudflare"
							}
						}
					}

					label(.class("field")) {
						span { "Custom" }
						textarea(
							.name("config[trustedProxies][custom]"),
							.placeholder("One IP address or CIDR range per line"),
						) {
							model.config.trustedProxies.custom.joined(separator: "\n")
						}
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

				// MARK: compression

				div(.class("field")) {
					span { "Compression" }
					div(.class("flex gap-2")) {
						label(.class("checkbox")) {
							input.checkbox(
								type: .boolean,
								name: "config[compression][enable]",
								.checked.when(model.config.compression.enable),
								.x.model("compression.enable"),
							)
							"Enable"
						}

						label(.class("checkbox")) {
							input.checkbox(
								type: .boolean,
								name: "config[compression][customize]",
								.checked.when(model.config.compression.customize),
								.x.model("compression.customize"),
							)
							"Customize"
						}
					}
				}

				fieldset.when("compression.enable && compression.customize") {
					div(.class("field")) {
						span { "Gzip" }
						div(.class("flex gap-2")) {
							label(.class("checkbox")) {
								input.checkbox(
									type: .boolean,
									name: "config[compression][gzipEnable]",
									.checked.when(model.config.compression.gzipEnable),
									.x.model("compression.gzipEnable"),
								)
								"Enable"
							}

							input(
								.type(.number),
								.name("config[compression][gzipLevel]"),
								.value(model.config.compression.gzipLevel.map { String($0.rawValue) } ?? ""),
								.placeholder("Level 1-9"),
								.min(1),
								.max(9),
								.step(1),
								.class("grow"),
								.x.bind("disabled", "!compression.gzipEnable"),
							)
						}
					}

					div(.class("field")) {
						span { "Zstd" }
						div(.class("flex gap-2")) {
							label(.class("checkbox")) {
								input.checkbox(
									type: .boolean,
									name: "config[compression][zstdEnable]",
									.checked.when(model.config.compression.zstdEnable),
									.x.model("compression.zstdEnable"),
								)
								"Enable"
							}

							select(
								.name("config[compression][zstdLevel]"),
								.class("grow"),
								.x.bind("disabled", "!compression.zstdEnable"),
							) {
								for level in Caddy.Config.Compression.ZstdLevel.allCases {
									option(
										.value(level.rawValue),
										.selected.when(model.config.compression.zstdLevel == level),
									) { level.rawValue }
								}
							}
						}
					}

					label(.class("field")) {
						span { "Minimum Length" }
						input(
							.type(.number),
							.name("config[compression][minimumLength]"),
							.value(model.config.compression.minimumLength.map(String.init) ?? ""),
							.placeholder("byte threshold"),
							.min(0),
						)
					}
				}

				hr()

				// MARK: caching

				div(.class("field")) {
					span { "Caching" }
					label(.class("checkbox")) {
						input.checkbox(
							type: .boolean,
							name: "config[cache][enable]",
							.checked.when(model.config.cache.enable),
							.x.model("cache.enable"),
						)
						"Enable"
					}
				}

				fieldset.when("cache.enable") {
					label(.class("field")) {
						span { "Max Age" }
						input(
							.type(.text),
							.name("config[cache][maxAge]"),
							.value(model.config.cache.maxAge.map(String.init) ?? ""),
							.placeholder("seconds, default 3600"),
						)
					}

					div(.class("field")) {
						span { "Visibility" }
						div(.class("flex gap-2")) {
							label(.class("radio")) {
								input(
									.type(.radio),
									.name("config[cache][visibility]"),
									.value("public"),
									.checked.when(model.config.cache.visibility == .public),
								)
								"Public"
							}

							label(.class("radio")) {
								input(
									.type(.radio),
									.name("config[cache][visibility]"),
									.value("private"),
									.checked.when(model.config.cache.visibility == .private),
								)
								"Private"
							}
						}
					}

					div(.class("field")) {
						span { "Conditions" }
						label(.class("checkbox")) {
							input.checkbox(
								type: .boolean,
								name: "config[cache][immutable]",
								.checked.when(model.config.cache.immutable),
							)
							"Immutable"
						}
					}
				}

				hr()

				// MARK: cors

				div(.class("field")) {
					span { "CORS" }
					label(.class("checkbox")) {
						input.checkbox(
							type: .boolean,
							name: "config[cors][enable]",
							.checked.when(model.config.cors.enable),
							.x.model("cors.enable"),
						)
						"Enable"
					}
				}

				fieldset.when("cors.enable") {
					label(.class("field")) {
						span { "Origins" }
						textarea(
							.name("config[cors][origins]"),
							.placeholder("* or one origin per line"),
						) {
							model.config.cors.origins.joined(separator: "\n")
						}
					}

					label(.class("field")) {
						span { "Methods" }
						textarea(
							.name("config[cors][methods]"),
							.placeholder("One method per line"),
						) {
							model.config.cors.methods.joined(separator: "\n")
						}
					}

					label(.class("field")) {
						span { "Headers" }
						textarea(
							.name("config[cors][headers]"),
							.placeholder("One header per line"),
						) {
							model.config.cors.headers.joined(separator: "\n")
						}
					}

					div(.class("field")) {
						span { "Credentials" }
						label(.class("checkbox")) {
							input.checkbox(
								type: .boolean,
								name: "config[cors][credentials]",
								.checked.when(model.config.cors.credentials),
							)
							"Allow"
						}
					}

					label(.class("field")) {
						span { "Max Age" }
						input(
							.type(.text),
							.name("config[cors][maxAge]"),
							.value(model.config.cors.maxAge.map(String.init) ?? ""),
							.placeholder("seconds"),
						)
					}
				}

				hr()

				// MARK: logging

				div(.class("field")) {
					span { "Logging" }
					label(.class("checkbox")) {
						input.checkbox(
							type: .boolean,
							name: "config[logging][enable]",
							.checked.when(model.config.logging.enable),
							.x.model("logging.enable"),
						)
						"Enable"
					}
				}

				fieldset.when("logging.enable") {
					label(.class("field")) {
						span { "Output" }
						input(
							.type(.text),
							.name("config[logging][output]"),
							.value(model.config.logging.output),
							.placeholder("Leave blank to use the default path"),
						)
					}

					div(.class("field")) {
						span { "Format" }
						div(.class("flex gap-2")) {
							label(.class("radio")) {
								input(
									.type(.radio),
									.name("config[logging][format]"),
									.value("console"),
									.checked.when(model.config.logging.format == .console),
								)
								"Console"
							}

							label(.class("radio")) {
								input(
									.type(.radio),
									.name("config[logging][format]"),
									.value("json"),
									.checked.when(model.config.logging.format == .json),
								)
								"JSON"
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
