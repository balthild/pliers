import Elementary
import Vapor
import VaporElementary

extension Request {
	func render(@HTMLBuilder content: () -> some HTML & Sendable) -> HTMLResponse {
		return HTMLResponse {
			content().environment(UI.Context.$key, self)
		}
	}
}
