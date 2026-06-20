import Elementary
import Foundation
import Path
import Vapor

extension UI.Page {
	struct BrowseFiles: HTMLDocument {
		typealias Entry = (
			name: String,
			path: Path,
			dir: Bool,
			owner: String,
			mode: UInt16,
		)

		let path: Path
		let entries: [Entry]

		var title: String { "Files" }

		var head: some HTML {
			UI.Component.CommonHead()
		}

		var body: some HTML {
			UI.Layout.Dashboard {
				h2 { "Files" }
				hr()

				p(.class("text-sm mb-2")) {
					"Current Path: "
					code { path.string }
				}

				table {
					thead {
						tr {
							th { "Name" }
							th { "Owner" }
							th { "Mode" }
						}
					}

					tbody {
						if path.string != "/" {
							tr {
								td {
									a(.href(link(to: path.parent))) { ".." }
								}
								td {}
								td {}
							}
						}

						for entry in entries {
							tr {
								td {
									if entry.dir {
										a(.href(link(to: entry.path))) { "\(entry.name)/" }
									} else {
										entry.name
									}
								}
								td { entry.owner }
								td { "\(String(entry.mode, radix: 8))" }
							}
						}

						if entries.isEmpty {
							tr {
								td(.colspan(3), .class("text-center text-gray-500")) {
									"This directory is empty."
								}
							}
						}
					}
				}
			}
		}

		private func link(to path: Path) -> String {
			var url = URLComponents()
			url.path = "/files"
			url.queryItems = [
				.init(name: "path", value: path.string)
			]

			return url.string ?? "/files"
		}
	}
}
