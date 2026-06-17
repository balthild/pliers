import Elementary

extension UI.Component {
	struct CommonHead: HTML {
		var body: some HTML {
			meta(.charset(.utf8))
			meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))

			link(.rel(.stylesheet), .href("/dist/main.css"))

			script(.src("https://unpkg.com/alpinejs@3"), .defer) {}
		}
	}
}
