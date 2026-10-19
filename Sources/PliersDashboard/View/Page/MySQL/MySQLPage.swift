import Elementary
import PliersCommon
import Vapor

extension View.Page {
	struct MySQLPage: HTMLPage {
		let status: String

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "MySQL" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			View.Component.ServiceControl(
				status: status,
				prefix: "/mysql/service",
			)
		}
	}
}
