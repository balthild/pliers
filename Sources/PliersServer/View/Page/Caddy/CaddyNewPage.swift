import Elementary

extension View.Page {
	struct CaddyNewPage: HTMLPage {
		let model: Caddy

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "Caddy" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			View.Page.CaddyFormView(model: model)
		}
	}
}
