import Elementary

extension View.Page {
	struct CronEditPage: HTMLPage {
		let model: Cron

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Cron" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			View.Page.CronFormView(model: model)
		}
	}
}
