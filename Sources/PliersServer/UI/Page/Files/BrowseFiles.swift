import Elementary
import Foundation
import Vapor

extension UI.Page {
	struct BrowseFiles: HTMLDocument {
		typealias Entry = (
			name: String,
			url: URL,
			owner: String,
			mode: UInt16,
			isDirectory: Bool,
			isSymlink: Bool,
		)

		let path: String
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
					code { path }
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
						if path != "/" {
							let parent = URL(filePath: path).deletingLastPathComponent()
							tr {
								td {
									a(.href(link(to: parent))) { ".." }
								}
								td {}
								td {}
							}
						}

						for entry in entries {
							tr {
								td {
									if entry.isDirectory {
										a(.href(link(to: entry.url))) { "\(entry.name)/" }
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

		private func link(to url: URL) -> String {
			guard !url.path.isEmpty else {
				return "/files"
			}

			var url = URLComponents()
			url.path = "/files"
			url.queryItems = [
				.init(name: "path", value: url.path)
			]

			return url.string ?? "/files"
		}
	}
}
