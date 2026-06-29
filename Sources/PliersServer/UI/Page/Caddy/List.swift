import Elementary
import Foundation
import Path
import Vapor

extension UI.Page.Caddy {
	struct List: HTMLDocument {
		let sites: [Caddy]

		var title: String { "Caddy" }

		var head: some HTML {
			UI.Component.CommonHead()
		}

		var body: some HTML {
			UI.Layout.Dashboard {
				h2 { title }
				hr()

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
									switch site.tls {
									case .some(.acme): "ACME"
									case .some(.file): "Custom"
									case .none: ""
									}
								}
								td {
									switch site.backend {
									case .some(.proxy): "Proxy"
									case .some(.file): "File"
									case .some(.php): "PHP"
									case .none: ""
									}
								}
								td {
									div(.class("flex gap-2")) {
										UI.Component.ErrorBoundary {
											a(.href("/caddy/\(try site.requireID())")) { "Edit" }
										}
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
}
