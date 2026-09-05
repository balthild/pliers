import Elementary
import Foundation
import Path
import Vapor

extension View.Page {
	struct ProgressPage: HTMLPage {
		let id: UUID
		let snapshot: ProgressData
		let redirect: String
		let title: String

		let layout = View.Layout.DashboardLayout<Self>()

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			Alpine.data(
				"progress",
				"""
				() => ({
					data: \(try snapshot.json()),

					get message() {
						return this.data.message || 'Working...';
					},

					get finished() {
						return this.data.status === "done" || this.data.status === "error";
					},

					init() {
						const source = new EventSource("/job/\(id.uuidString)/progress");

						source.addEventListener("message", (event) => {
							const data = JSON.parse(event.data);
							this.update(data);

							if (this.finished) {
								source.close();
							}
						});
					},

					update(data) {
						this.data = data;
					},

					redirect() {
						location.href = \(redirect.quoteJSON);
					},

					binding: {
						track: {
							["x-bind:class"]() {
								switch (this.data.status) {
									case "done":
										return "bg-green-700";
									case "error":
										return "bg-red-700";
									default:
										return "bg-sky-600";
								}
							},
							["x-bind:style"]() {
								return `width: ${this.data.progress * 100}% !important`;
							}
						},
					},
				})
				""",
			)

			div(.class("w-full max-w-160"), .x.data("progress")) {
				p(.class("mb-2 text-sm"), .x.text("message")) {}

				div(.class("mb-4 w-full h-1.5 rounded bg-gray-200")) {
					div(.class("w-0 h-1.5 rounded transition-[width]"), .x.bind("binding.track")) {}
				}

				div(.class("text-right")) {
					button(
						.class("btn primary"),
						.x.bind("disabled", "!finished"),
						.x.on("click", "redirect"),
					) { "Back" }
				}
			}
		}
	}
}
