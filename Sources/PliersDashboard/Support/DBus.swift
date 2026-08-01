import DBUS
import PliersCommon
import PliersSystemd
import Vapor

extension Request {
	var dbus: DBusProxy {
		DBusProxy(logger: self.logger)
	}
}

struct DBusProxy {
	let logger: Logger

	var systemd: DBusSystemdProxy {
		DBusSystemdProxy(logger: self.logger)
	}
}

struct DBusSystemdProxy {
	let logger: Logger

	func manager<T: Sendable>(
		action: @Sendable @escaping (OrgFreedesktopSystemd1Manager) async throws -> T
	) async -> Result<T, Error> {
		await Result {
			try await DBusClient.withSystemBus(
				auth: .external(userID: String(getuid())),
				logger: self.logger,
			) { connection in
				let proxy = OrgFreedesktopSystemd1ManagerProxy(
					connection: connection,
					destination: "org.freedesktop.systemd1",
					path: "/org/freedesktop/systemd1",
				)

				return try await action(proxy)
			}
		}
	}

	func props<T: Sendable>(
		_ path: String,
		action: @Sendable @escaping (OrgFreedesktopDBusProperties) async throws -> T,
	) async -> Result<T, Error> {
		await Result {
			try await DBusClient.withSystemBus(
				auth: .external(userID: String(getuid())),
				logger: self.logger,
			) { connection in
				let proxy = OrgFreedesktopDBusPropertiesProxy(
					connection: connection,
					destination: "org.freedesktop.systemd1",
					path: path,
				)

				return try await action(proxy)
			}
		}
	}
}

extension DBusSystemdProxy {
	func status(_ service: String) async throws -> Result<String, Error> {
		await Result {
			let unit =
				try await self
				.manager { try await $0.getUnit(name: service) }
				.expect("failed to get systemd service unit")

			let status =
				try await self
				.props(unit) {
					try await $0.get(
						interfaceName: "org.freedesktop.systemd1.Unit",
						propertyName: "ActiveState",
					)
				}
				.expect("failed to get systemd service status")

			return try status.value.string
				.expect("unexpected systemd service status")
		}
	}
}
