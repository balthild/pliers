import Elementary
import PliersCommon
import Vapor

extension UI.Page {
	struct Overview: HTMLPage {
		@UI.Context var req: Request

		let layout = UI.Layout.Dashboard<Self>()

		var title: String { "Overview" }

		@HTMLBuilder
		func body() throws -> some HTML {
			"TODO: Overview Page"
		}
	}
}
