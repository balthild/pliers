import Elementary

extension View.Page {
	struct MySQLAccountEditPage: HTMLPage {
		let model: MySQLAccount

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "MySQL" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			View.Page.MySQLAccountFormView(model: model)
		}
	}
}
