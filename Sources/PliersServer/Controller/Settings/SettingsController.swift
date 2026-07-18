import Fluent
import Vapor
import VaporElementary

struct SettingsController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("settings")
			.grouped(User.requireLoggedIn())

		group.get(use: self.index)
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let _ = try await user.$passkeys.get(on: req.db)

		return try await req.render {
			View.Page.SettingsPage()
		}
	}
}
