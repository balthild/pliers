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
	func index(req: Request) async throws -> HTMLResponse {
		return req.render {
			UI.Page.Settings()
		}
	}
}
