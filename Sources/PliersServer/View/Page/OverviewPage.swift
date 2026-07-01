import Elementary
import PliersCommon
import Vapor

extension View.Page {
	struct OverviewPage: HTMLPage {
		@View.Context var req: Request

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Overview" }

		@HTMLBuilder
		func body() throws -> some HTML {
			"TODO: Overview Page"
		}
	}
}
