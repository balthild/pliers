import Elementary

extension View.Component {
	struct CommonHead: HTML {
		var body: some HTML {
			meta(.charset(.utf8))
			meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))

			View.Component.ViteAssets(entries: ["main.ts"])
		}
	}
}
