import Fluent
import Vapor

struct AuthController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("auth")

		group.get(use: self.index)
	}

	@Sendable
	func index(req: Request) async throws -> [UserDTO] {
		// DEBUG: list all users
		try await User.query(on: req.db).all().map { $0.toDTO() }
	}
}
