import Elementary

extension View.Page {
	struct MySQLEditPage: HTMLPage {
		let model: MySQL

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "MySQL" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			View.Page.MySQLFormView(model: model)
		}
	}
}
