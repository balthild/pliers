import PliersCommon
import Vapor

struct PHPServiceController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped(User.requireLoggedIn())

		group.group("php", ":version", "service") { group in
			group.post("start", use: self.start)
			group.post("stop", use: self.stop)
			group.post("restart", use: self.restart)
			group.post("reload", use: self.reload)
		}
	}

	@Sendable
	func start(req: Request) async throws -> Response {
		let name = try Self.name(req)

		let _ = try await req.dbus.systemd
			.manager { try await $0.startUnit(name: name, mode: "replace") }
			.alert("failed to start php-fpm service")

		return req.redirect(.back)
	}

	@Sendable
	func stop(req: Request) async throws -> Response {
		let name = try Self.name(req)

		let _ = try await req.dbus.systemd
			.manager { try await $0.stopUnit(name: name, mode: "replace") }
			.alert("failed to stop php-fpm service")

		return req.redirect(.back)
	}

	@Sendable
	func restart(req: Request) async throws -> Response {
		let name = try Self.name(req)

		let _ = try await req.dbus.systemd
			.manager { try await $0.restartUnit(name: name, mode: "replace") }
			.alert("failed to restart php-fpm service")

		return req.redirect(.back)
	}

	@Sendable
	func reload(req: Request) async throws -> Response {
		let name = try Self.name(req)

		let _ = try await req.dbus.systemd
			.manager { try await $0.reloadUnit(name: name, mode: "replace") }
			.alert("failed to reload php-fpm service")

		return req.redirect(.back)
	}

	private static func name(_ req: Request) throws -> String {
		let version: PHP.Version = try req.parameters.get("version")
			.alert("invalid version")

		return PHPConfigurator(version: version).service
	}
}
