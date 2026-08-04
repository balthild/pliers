import DBUS
import PliersCommon
import PliersDBus
import Vapor

struct DBusServer: LifecycleHandler {
	func didBoot(_ app: Application) throws {
		_ = Task.detached(priority: .background) {
			try await DBusClient.system(logger: app.logger) { connection in
				let server = DBusObjectServer(connection: connection, logger: app.logger)

				let name = "com.balthild.Pliers"
				let path = "/com/balthild/Pliers"

				let interface = DBusHandler(app: app).makeInterface()
				await server.export(.init(path: path, interfaces: [interface]))

				await connection.setMessageHandler({ message in
					let uid = await message.sender.flatMapAsync { sender in
						// TODO: fix the deadlock bug
						// as a workaround, start another connection to avoid deadlock
						try? await DBusClient.system(logger: app.logger) { connection in
							try? await self.getConnectionUnixUser(
								connection: connection,
								sender: sender,
							)
						}
					}

					await DBusHandler.$sender.withValue(uid) {
						await server.handle(message: message)
					}
				})

				_ = try await self.requestName(connection: connection, name: name, flag: 0b111)
				app.logger.notice("DBus interface exported on \(name) \(path)")
				try await app.running?.onStop.get()
				_ = try await self.releaseName(connection: connection, name: name)
			}
		}
	}
}

// MARK: PliersDBus/DBus.swift

extension DBusServer {
	private enum DBusCodegenError: Error { case typeMismatch }

	private func requestName(
		connection: any DBusServerConnection,
		name: String,
		flag: UInt32,
	) async throws -> UInt32 {
		let request = DBusRequest.createMethodCall(
			destination: "org.freedesktop.DBus",
			path: "/org/freedesktop/DBus",
			interface: "org.freedesktop.DBus",
			method: "RequestName",
			body: [.string(name), .uint32(flag)],
		)
		guard let reply = try await connection.send(request) else { throw DBusError.missingReply }
		guard reply.body.indices.contains(0) else { throw DBusCodegenError.typeMismatch }
		guard case .uint32(let _v0) = reply.body[0] else { throw DBusCodegenError.typeMismatch }
		return _v0
	}

	private func releaseName(
		connection: any DBusServerConnection,
		name: String,
	) async throws -> UInt32 {
		let request = DBusRequest.createMethodCall(
			destination: "org.freedesktop.DBus",
			path: "/org/freedesktop/DBus",
			interface: "org.freedesktop.DBus",
			method: "ReleaseName",
			body: [.string(name)],
		)
		guard let reply = try await connection.send(request) else { throw DBusError.missingReply }
		guard reply.body.indices.contains(0) else { throw DBusCodegenError.typeMismatch }
		guard case .uint32(let _v0) = reply.body[0] else { throw DBusCodegenError.typeMismatch }
		return _v0
	}

	public func getConnectionUnixUser(
		connection: any DBusServerConnection,
		sender: String,
	) async throws -> UInt32 {
		let request = DBusRequest.createMethodCall(
			destination: "org.freedesktop.DBus",
			path: "/org/freedesktop/DBus",
			interface: "org.freedesktop.DBus",
			method: "GetConnectionUnixUser",
			body: [.string(sender)],
		)
		guard let reply = try await connection.send(request) else { throw DBusError.missingReply }
		guard reply.body.indices.contains(0) else { throw DBusCodegenError.typeMismatch }
		guard case .uint32(let _v0) = reply.body[0] else { throw DBusCodegenError.typeMismatch }
		return _v0
	}
}
