import Elementary

extension View.Component {
	struct ServiceStatus: HTML {
		let status: String

		var body: some HTML {
			span(.class("inline-flex gap-1.5 items-center")) {
				span(.class(["size-1.75 rounded-full inline-block", color])) {}
				span { status.capitalized }
			}
		}

		private var color: String {
			switch status {
			case "active":
				return "bg-green-600"
			case "inactive", "failed":
				return "bg-red-600"
			default:
				return "bg-yellow-600"
			}
		}
	}
}
