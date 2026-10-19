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
		let status = try await req.dbus.systemd.status("mysql.service")
			.alert("failed to get mysql service status")

		return try await req.render {
			View.Page.MySQLPage(
				status: status
			)
		}
	}
}
