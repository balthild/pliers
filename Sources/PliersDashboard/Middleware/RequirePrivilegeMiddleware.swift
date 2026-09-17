import Vapor

final class RequirePrivilegeMiddleware: AsyncMiddleware {
	let privilege: User.Privilege

	init(_ privilege: User.Privilege) {
		self.privilege = privilege
	}

	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		guard let user = request.auth.get(User.self), user.hasPrivilege(self.privilege) else {
			throw Abort(.forbidden)
		}

		return try await next.respond(to: request)
	}
}
