import Vapor

extension Authenticatable {
	public static func guestMiddleware(path: String) -> Middleware {
		return GuestMiddleware<Self>(path: path)
	}
}

private final class GuestMiddleware<A: Authenticatable>: Middleware {
	let path: String

	init(path: String) {
		self.path = path
	}

	func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
		if !request.auth.has(A.self) {
			return next.respond(to: request)
		}

		let redirect = request.redirect(to: self.path)
		return request.eventLoop.makeSucceededFuture(redirect)
	}
}
