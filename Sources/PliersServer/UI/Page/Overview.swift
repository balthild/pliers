import Elementary
import PliersCommon
import Vapor

extension UI.Page {
	struct Overview: HTMLDocument {
		@UI.Context var req: Request

		var title: String { "Overview" }

		var head: some HTML {
			UI.Component.CommonHead()
		}

		var body: some HTML {
			UI.Layout.Dashboard {
				"TODO: Overview Page"
			}
		}
	}
}
