import Elementary
import Foundation
import Path
import Vapor

extension View.Page {
	struct CaddyListPage: HTMLPage {
		let sites: [Caddy]

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Caddy" }

		@HTMLBuilder
		func body() throws -> some HTML {
			h2 { title }
			hr()

			div(.class("mb-2 flex gap-2")) {
				a(.class("btn"), .href("/caddy/new")) { "New" }
			}

			table {
				thead {
					tr {
						th { "Name" }
						th { "TLS" }
						th { "Backend" }
						th {}
					}
				}

				tbody {
					for site in sites {
						tr {
							td {
								for domain in site.domains {
									p { domain }
								}
							}
							td {
								switch site.config.tls {
								case .some(.acme): "ACME"
								case .some(.file): "Custom"
								case .none: ""
								}
							}
							td {
								switch site.config.backend {
								case .some(.proxy): "Proxy"
								case .some(.file): "File"
								case .some(.php): "PHP"
								case .none: ""
								}
							}
							td {
								div(.class("flex gap-2")) {
									a(.href("/caddy/\(try site.requireID())")) { "Edit" }
								}
							}
						}
					}

					if sites.isEmpty {
						tr {
							td(.colspan(4), .class("text-center text-gray-500")) {
								"No data."
							}
						}
					}
				}
			}
		}
	}
}
