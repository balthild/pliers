import Elementary

extension View.Component {
	struct CommonHead: HTML {
		var body: some HTML {
			meta(.charset(.utf8))
			meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))

			link(.rel(.stylesheet), .href("/dist/main.css"))

			script(.src("https://unpkg.com/@alpinejs/persist@3/dist/cdn.min.js"), .defer) {}
			script(.src("/js/alpine-history.js"), .defer) {}
			script(.src("https://unpkg.com/alpinejs@3/dist/cdn.min.js"), .defer) {}
		}
	}
}
