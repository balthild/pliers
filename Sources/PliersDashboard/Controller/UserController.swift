import Fluent
import PliersCommon
import Vapor

struct UserController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.admin))
			.group("user") { group in
				group.get(use: self.index)

				group.group(":id") { group in
					group.get(use: self.edit)
					group.post("update", use: self.update)
				}
			}
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		let users = try await User.query(on: req.db).sort(\.$username).all()

		return try await req.render {
			View.Page.UserListPage(users: users)
		}
	}

	@Sendable
	func edit(req: Request) async throws -> Response {
		let model = try await req.find(User.self, "id")

		return try await req.render {
			View.Page.UserEditPage(model: model)
		}
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		struct Input: Content {
			let privileges: Set<User.Privilege>
		}

		let input = try req.content.decode(Input.self)
		let model = try await req.find(User.self, "id")

		let user = try req.auth.require(User.self)
		if model.id == user.id, !input.privileges.contains(.admin) {
			throw AlertError("you cannot remove your own admin privilege")
		}

		model.privileges = input.privileges
		try await model.update(on: req.db)

		return req.redirect(.back)
	}
}
