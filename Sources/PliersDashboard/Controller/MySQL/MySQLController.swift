import Fluent
import PliersCommon
import Vapor
import VaporElementary

struct MySQLController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.mysql))
			.group("mysql") { group in
				group.get(use: self.index)
			}
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let users: [UUID: User]
		if user.isAdmin {
			users = try await User.query(on: req.db).all()
				.keyed { try $0.requireID() }
		} else {
			users = [:]
		}

		let owner: User?
		if user.isAdmin, let id: UUID = req.query["user"] {
			owner = users[id]
		} else {
			owner = user
		}

		let accounts = try await owner?.$mysqlAccounts.get(on: req.db) ?? []

		let status = try await req.dbus.systemd.status(C.mysql.service)
			.alert("failed to get mysql service status")

		return try await req.render {
			View.Page.MySQLPage(
				status: status,
				users: users,
				owner: owner,
				accounts: accounts,
			)
		}
	}
}
