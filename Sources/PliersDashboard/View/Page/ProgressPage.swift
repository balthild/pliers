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

					init() {
						const source = new EventSource("/job/\(id.uuidString)/progress");

						source.addEventListener("message", (event) => {
							const data = JSON.parse(event.data);
							this.update(data);

							if (data.status === "done" || data.status === "error") {
								source.close();
							}
						});
					},

					update(data) {
						this.data = data;
					},
				})
				""",
			)

			div(.x.data("progress")) {
				// TEST
				p {
					"progress = "
					span(.x.text("data.progress")) { "..." }
				}
				p {
					"message = "
					span(.x.text("data.message")) { "..." }
				}
			}
		}
	}
}
