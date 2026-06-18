import Elementary
import Vapor
import VaporElementary

extension Request {
	enum SpecialRedirect {
		case back
	}

	func redirect(_ location: SpecialRedirect) -> Response {
		switch location {
		case .back:
			let referrer = self.headers.first(name: .referer) ?? "/"
			return self.redirect(to: referrer)
		}
	}
}

extension Request {
	func render(@HTMLBuilder content: () -> some HTML & Sendable) -> HTMLResponse {
		return HTMLResponse {
			content().environment(UI.Context.$key, self)
		}
	}
}
