import PliersCommon
import Vapor

struct PHPServiceController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.php))
			.group("php", ":version", "service") { group in
				group.post("start", use: self.start)
				group.post("stop", use: self.stop)
				group.post("restart", use: self.restart)
				group.post("reload", use: self.reload)
			}
	}

	@Sendable
	func start(req: Request) async throws -> Response {
		let version: PHP.Version = try req.parameters.get("version")
			.alert("invalid php version")

		let service = version.configurator.service

		let _ = try await req.dbus.systemd
			.manager { try await $0.startUnit(name: service, mode: "replace") }
			.alert("failed to start php-fpm service")

		return req.redirect(.back)
	}

	@Sendable
	func stop(req: Request) async throws -> Response {
		let version: PHP.Version = try req.parameters.get("version")
			.alert("invalid php version")

		let service = version.configurator.service

		let _ = try await req.dbus.systemd
			.manager { try await $0.stopUnit(name: service, mode: "replace") }
			.alert("failed to stop php-fpm service")

		return req.redirect(.back)
	}

	@Sendable
	func restart(req: Request) async throws -> Response {
		let version: PHP.Version = try req.parameters.get("version")
			.alert("invalid php version")

		let service = version.configurator.service

		let _ = try await req.dbus.systemd
			.manager { try await $0.restartUnit(name: service, mode: "replace") }
			.alert("failed to restart php-fpm service")

		return req.redirect(.back)
	}

	@Sendable
	func reload(req: Request) async throws -> Response {
		let version: PHP.Version = try req.parameters.get("version")
			.alert("invalid php version")

		let service = version.configurator.service

		let _ = try await req.dbus.systemd
			.manager { try await $0.reloadUnit(name: service, mode: "replace") }
			.alert("failed to reload php-fpm service")

		return req.redirect(.back)
	}
}
