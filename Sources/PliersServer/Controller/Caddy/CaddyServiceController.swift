import DBUS
import Glibc
import PliersCommon
import PliersSystemd
import Vapor

struct CaddyServiceController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped(User.requireLoggedIn())

		group.group("caddy", "service") { group in
			group.post("start", use: self.start)
			group.post("stop", use: self.stop)
			group.post("restart", use: self.restart)
			group.post("reload", use: self.reload)
		}
	}

	@Sendable
	func start(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.startUnit(name: "caddy.service", mode: "replace") }
			.alert("failed to start caddy service")

		return req.redirect(.back)
	}

	@Sendable
	func stop(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.stopUnit(name: "caddy.service", mode: "replace") }
			.alert("failed to stop caddy service")

		return req.redirect(.back)
	}

	@Sendable
	func restart(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.restartUnit(name: "caddy.service", mode: "replace") }
			.alert("failed to restart caddy service")

		return req.redirect(.back)
	}

	@Sendable
	func reload(req: Request) async throws -> Response {
		let _ = try await req.dbus.systemd
			.manager { try await $0.reloadUnit(name: "caddy.service", mode: "replace") }
			.alert("failed to reload caddy service")

		return req.redirect(.back)
	}
}
