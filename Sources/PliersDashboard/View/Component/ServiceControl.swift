import Elementary

extension View.Component {
	struct ServiceControl: HTML {
		let status: String
		let prefix: String

		var body: some HTML {
			div(.class("text-sm flex gap-1.5 items-center")) {
				View.Component.ServiceStatus(status: status)

				// a dummy button to prevent layout shift
				span(.class("btn text-xs px-0 w-0 invisible")) { "#" }

				if status == "active" {
					form(.method(.post), .action("\(prefix)/stop")) {
						button(.type(.submit), .class("danger text-xs")) { "Stop" }
					}
					form(.method(.post), .action("\(prefix)/restart")) {
						button(.type(.submit), .class("text-xs")) { "Restart" }
					}
					form(.method(.post), .action("\(prefix)/reload")) {
						button(.type(.submit), .class("text-xs")) { "Reload" }
					}
				}

				if status == "inactive" || status == "failed" {
					form(.method(.post), .action("\(prefix)/start")) {
						button(.type(.submit), .class("success text-xs")) { "Start" }
					}
				}
			}
		}
	}
}
