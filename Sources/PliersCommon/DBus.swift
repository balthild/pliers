import DBUS
import Glibc
import Logging

extension DBusClient {
	@inline(__always)
	public static func system<R: Sendable>(
		logger: Logger = Logger(label: "dbus.client"),
		_ handler: @Sendable @escaping (Connection) async throws -> R,
	) async throws -> R {
		try await self.withSystemBus(auth: .me, logger: logger, handler)
	}
}

extension AuthType {
	@inline(__always)
	public static var me: Self {
		.external(userID: String(getuid()))
	}
}
