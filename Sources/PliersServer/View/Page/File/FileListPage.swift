import Elementary
import Path
import Vapor

extension View.Page {
	struct FileListPage: HTMLPage, FileViewMixin {
		typealias Entry = (
			name: String,
			path: Path,
			dir: Bool,
			owner: String,
			mode: UInt16,
		)

		let path: Path
		let entries: [Entry]

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Filesystem" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			p(.class("text-sm mb-2")) {
				"Current Directory: "
				code { path.string }
			}

			dialogs
			actions
			files
		}

		@HTMLBuilder
		private var dialogs: some HTML {
			// MARK: delete_dialog

			Alpine.data(
				"delete_dialog",
				"""
				() => ({
					path: '',

					get url() {
						if (!this.path) return '/404';
						const url = new URL(`/file/delete`, location.origin);
						url.searchParams.set('path', this.path);
						return url.toString();
					},

					show(path) {
						this.path = path;
						this.$root.showModal();
					},

					cancel() {
						this.path = '';
						this.$root.close();
					},
				})
				""",
			)

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("delete_dialog"),
				.x.data("delete_dialog"),
			) {
				header { "Delete" }

				main {
					section(.class("mb-3 text-sm space-y-1")) {
						p {
							"Deleting "
							code(.x.text("path")) {}
							" and all its contents."
						}
						p { "This action cannot be undone. Type the path below to confirm." }
					}

					form(
						.method(.post),
						.class("form"),
						.x.bind("action", "url"),
					) {
						label(.class("field")) {
							span { "Path" }
							input(
								.name("confirm"),
								.type(.text),
								.required,
							)
						}

						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("danger")) { "Delete" }
						}
					}
				}
			}

			// MARK: chmod_dialog

			Alpine.data(
				"chmod_dialog",
				"""
				() => ({
					path: '',
					mode: '',

					get url() {
						if (!this.path) return '/404';
						const url = new URL(`/file/chmod`, location.origin);
						url.searchParams.set('path', this.path);
						return url.toString();
					},

					show(path, mode) {
						this.path = path;
						this.mode = mode;
						this.$root.showModal();
					},

					cancel() {
						this.path = '';
						this.mode = '';
						this.$root.close();
					},
				})
				""",
			)

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("chmod_dialog"),
				.x.data("chmod_dialog"),
			) {
				header { "Chmod" }

				main {
					section(.class("mb-3 text-sm space-y-1")) {
						p {
							"Changing mode for "
							code(.x.text("path")) {}
						}
						p { "Enter the new mode in octal format." }
						p { "Setting the Sticky/SUID/SGID bits are not allowed here." }
					}

					form(
						.method(.post),
						.class("form"),
						.x.bind("action", "url"),
					) {
						label(.class("field")) {
							span { "Mode" }
							input(
								.name("mode"),
								.type(.text),
								.pattern("[0-7]{3}"),
								.required,
								.x.bind("value", "mode"),
							)
						}

						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("primary")) { "Save" }
						}
					}
				}
			}

			// MARK: unarchive_dialog

			Alpine.data(
				"unarchive_dialog",
				"""
				() => ({
					path: '',

					get url() {
						if (!this.path) return '/404';
						const url = new URL(`/file/unarchive`, location.origin);
						url.searchParams.set('path', this.path);
						return url.toString();
					},

					show(path) {
						this.path = path;
						this.$root.showModal();
					},

					cancel() {
						this.path = '';
						this.$root.close();
					},
				})
				""",
			)

			dialog(
				.closedby(.none),
				.class("w-100"),
				.id("unarchive_dialog"),
				.x.data("unarchive_dialog"),
			) {
				header { "Unarchive" }

				main {
					section(.class("mb-3 text-sm space-y-1")) {
						p {
							"Unarchiving "
							code(.x.text("path")) {}
						}
						p {
							"This will extract the contents of the archive into the current directory. Any existing files with the same name will be overwritten."
						}
					}

					form(
						.method(.post),
						.class("form"),
						.x.bind("action", "url"),
					) {
						div(.class("actions")) {
							button(.type(.button), .x.on("click", "cancel")) { "Cancel" }
							button(.type(.submit), .class("primary")) { "Unarchive" }
						}
					}
				}
			}
		}

		@HTMLBuilder
		private var actions: some HTML {
			div(.class("mb-2"), .x.data("{ action: false }")) {
				div(.class("flex gap-2"), .x.show("!action")) {
					button(.x.on("click", "action = 'mkdir'")) { "Mkdir" }
					button(.x.on("click", "action = 'create'")) { "Create" }
					button(.x.on("click", "action = 'upload'")) { "Upload" }
				}

				// MARK: mkdir

				form(
					.method(.post),
					.action(link(to: path, action: "mkdir")),
					.class("form max-w-100 p-2 border border-gray-400"),
					.x.cloak,
					.x.show("action == 'mkdir'"),
				) {
					label(.class("field")) {
						span { "Directory" }
						input(
							.name("directory"),
							.type(.text),
							.required,
						)
					}

					div(.class("actions")) {
						button(.type(.button), .x.on("click", "action = false")) { "Cancel" }
						button(.type(.submit), .class("primary")) { "Create" }
					}
				}

				// MARK: create

				form(
					.method(.post),
					.action(link(to: path, action: "create")),
					.class("form max-w-100 p-2 border border-gray-400"),
					.x.cloak,
					.x.show("action == 'create'"),
				) {
					label(.class("field")) {
						span { "Filename" }
						input(
							.name("filename"),
							.type(.text),
							.required,
						)
					}

					div(.class("actions")) {
						button(.type(.button), .x.on("click", "action = false")) { "Cancel" }
						button(.type(.submit), .class("primary")) { "Create" }
					}
				}

				// MARK: upload

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
									a(.href(link(to: entry.path, action: "edit"))) { entry.name }
								}
							}
							td { entry.owner }
							td { "\(String(entry.mode, radix: 8))" }
							td {
								div(.class("flex gap-2")) {
									let path = entry.path.string
									let mode = String(entry.mode, radix: 8)

									button(
										.class("link text-yellow-600"),
										.on(.click, "$('#chmod_dialog').show(\(path.quoteJSON), '\(mode)');"),
									) { "Chmod" }

									button(
										.class("link text-red-700"),
										.on(.click, "$('#delete_dialog').show(\(path.quoteJSON));"),
									) { "Delete" }

									if !entry.dir {
										a(.href(link(to: entry.path, action: "download"))) { "Download" }

										let pattern = /.*\.(tar|tar\.gz|tgz|tar\.bz2|tbz2|tar\.xz|txz)$/
										if path.wholeMatch(of: pattern) != nil {
											button(
												.class("link"),
												.on(.click, "$('#unarchive_dialog').show(\(path.quoteJSON));"),
											) { "Unarchive" }
										}
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
	}
}
