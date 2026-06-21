import Elementary
import Foundation
import Path
import Vapor

extension UI.Page {
	struct BrowseFile: HTMLDocument {
		typealias Entry = (
			name: String,
			path: Path,
			dir: Bool,
			owner: String,
			mode: UInt16,
		)

		let path: Path
		let entries: [Entry]

		var title: String { "Filesystem" }

		var head: some HTML {
			UI.Component.CommonHead()
		}

		var body: some HTML {
			UI.Layout.Dashboard {
				h2 { "Filesystem" }
				hr()

				p(.class("text-sm mb-2")) {
					"Current Path: "
					code { path.string }
				}

				dialogs
				actions
				files
			}
		}

		@HTMLBuilder
		private var dialogs: some HTML {
			Alpine.store(
				"fileActions",
				"""
				{
					action: false,
					path: '',

					url(action) {
						// DEBUG
						console.log(`Generating URL for action: ${action}`);
						return '';

						if (action !== this.action) return '';

						const url = new URL(`/file/${action}`, window.location.origin);
						url.searchParams.set('path', this.path);
						return url.toString();
					},

					delete(path) {
						this.action = 'delete';
						this.path = path;
						document.getElementById('file_actions').showModal();
					},

					chmod(path) {
						this.action = 'chmod';
						this.path = path;
						document.getElementById('file_actions').showModal();
					},

					cancel() {
						this.action = false;
						this.path = '';
						document.getElementById('file_actions').close();
					}
				}
				""",
			)

			dialog(.closedby(.none), .id("file_actions"), .class("w-100"), .x.data()) {
				header(.x.show("$store.fileActions.action === 'delete'")) { "Delete" }
				header(.x.show("$store.fileActions.action === 'chmod'")) { "Change Mode" }

				main(.x.show("$store.fileActions.action === 'delete'")) {
					section(.class("mb-2 text-sm space-y-1")) {
						p {
							"Deleting "
							code(.x.text("$store.fileActions.path")) {}
						}
						p { "Are you sure? This action cannot be undone." }
					}

					form(
						.method(.post),
						.class("flex justify-end gap-2"),
						.x.bind("action", "$store.fileActions.url('delete')"),
					) {
						button(.type(.button), .x.on("click", "$store.fileActions.cancel()")) { "Cancel" }
						button(.type(.submit), .class("danger")) { "Delete" }
					}
				}
			}
		}

		@HTMLBuilder
		private var actions: some HTML {
			div(.class("mb-2"), .x.data("{ action: false }")) {
				div(.class("flex gap-2"), .x.show("!action")) {
					button(.class("btn"), .x.on("click", "action = 'upload'")) { "Upload" }
					button(.class("btn"), .x.on("click", "action = 'mkdir'")) { "Mkdir" }
				}

				form(
					.method(.post),
					.action(link(to: path, action: "create")),
					.enctype(.multipartFormData),
					.class("form max-w-100 p-2 border border-gray-400"),
					.x.cloak,
					.x.show("action == 'upload'"),
				) {
					label(.class("field")) {
						span { "Filename" }
						input(
							.name("filename"),
							.type(.text),
							.required,
						)
					}

					label(.class("field")) {
						span { "Content" }
						input(
							.type(.file),
							.name("content"),
							.required,
						)
					}

					div(.class("actions")) {
						button(.type(.button), .x.on("click", "action = false")) { "Cancel" }
						button(.type(.submit), .class("primary")) { "Upload" }
					}
				}
			}
		}

		@HTMLBuilder
		private var files: some HTML {
			table {
				thead {
					tr {
						th { "Name" }
						th { "Owner" }
						th { "Mode" }
						th {}
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
							td {
								div(.class("flex gap-2")) {
									if !entry.dir {
										a(.href(link(to: entry.path, action: "download"))) { "Download" }

										button(
											.class("link text-orange-400"),
											.x.data(),
											.x.on("click", "$store.fileActions.chmod('\(entry.path.string)')"),
										) { "Chmod" }

										button(
											.class("link text-red-700"),
											.x.data(),
											.x.on("click", "$store.fileActions.delete('\(entry.path.string)')"),
										) { "Delete" }
									}
								}
							}
						}
					}

					if entries.isEmpty {
						tr {
							td(.colspan(4), .class("text-center text-gray-500")) {
								"This directory is empty."
							}
						}
					}
				}
			}
		}

		private func link(to path: Path, action: String? = nil) -> String {
			var url = URLComponents()

			if let action {
				url.path = "/file/\(action)"
			} else {
				url.path = "/file"
			}

			url.queryItems = [
				.init(name: "path", value: path.string)
			]

			return url.string ?? "/file"
		}
	}
}
