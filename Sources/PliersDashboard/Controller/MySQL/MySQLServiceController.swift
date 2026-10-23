import PliersCommon
import Vapor

struct MySQLServiceController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.mysql))
			.group("mysql", "service") { group in
				group.post("start", use: self.start)
				group.post("stop", use: self.stop)
				group.post("restart", use: self.restart)
				group.post("reload", use: self.reload)
			}
	}

	@Sendable
	func start(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.startUnit(name: C.mysql.service, mode: "replace") }
			.alert("failed to start mysql service")

		return req.redirect(.back)
	}

	@Sendable
	func stop(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.stopUnit(name: C.mysql.service, mode: "replace") }
			.alert("failed to stop mysql service")

		return req.redirect(.back)
	}

	@Sendable
	func restart(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.restartUnit(name: C.mysql.service, mode: "replace") }
			.alert("failed to restart mysql service")

		return req.redirect(.back)
	}

	@Sendable
	func reload(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.reloadUnit(name: C.mysql.service, mode: "replace") }
			.alert("failed to reload mysql service")

		return req.redirect(.back)
	}
}
