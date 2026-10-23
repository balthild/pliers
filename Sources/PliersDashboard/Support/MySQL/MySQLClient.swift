import Logging
import MySQLNIO
import NIOCore
import PliersCommon
import Vapor

extension Request {
	var mysql: MySQLClient {
		MySQLClient(logger: self.logger, eventLoop: self.eventLoop)
	}
}

extension Application {
	var mysql: MySQLClient {
		MySQLClient(logger: self.logger, eventLoop: self.eventLoopGroup.next())
	}
}

/// Runs MySQL statements over a single short-lived connection.
///
/// Pliers never keeps a MySQL connection open between requests: each operation opens a
/// connection, runs, and closes it. Administration connects as `root` over the local unix
/// socket, which MySQL authenticates with the `auth_socket` plugin, so no password is stored.
struct MySQLClient: Sendable {
	let logger: Logger
	let eventLoop: any EventLoop

	func withConnection<T: Sendable>(
		username: String = "root",
		password: String? = nil,
		database: String = "mysql",
		_ body: @Sendable (MySQLConnection) async throws -> T,
	) async throws -> T {
		let socket = try SocketAddress(unixDomainSocketPath: C.mysql.socket.string)

		let connection = try await MySQLConnection.connect(
			to: socket,
			username: username,
			database: database,
			password: password,
			tlsConfiguration: nil,
			on: self.eventLoop,
		).get()

		do {
			// `quoteMySQL` doubles backslashes, which is only correct while `NO_BACKSLASH_ESCAPES`
			// is off. Clearing it here makes that assumption hold whatever the server's global
			// mode is. MySQL normalizes the commas the REPLACE leaves behind.
			_ = try await connection.simpleQuery(
				"SET SESSION sql_mode = REPLACE(@@SESSION.sql_mode, 'NO_BACKSLASH_ESCAPES', '')"
			).get()

			let value = try await body(connection)
			try await connection.close().get()
			return value
		} catch {
			// `MySQLConnection` asserts its channel is closed before deinit.
			try? await connection.close().get()
			throw error
		}
	}

	/// Runs a simple (text protocol) statement and returns any rows it produced.
	///
	/// Account management cannot use the binary protocol at all: MySQL rejects
	/// `CREATE USER ... IDENTIFIED BY ?` as invalid syntax and provides no way to bind an
	/// account name, so callers escape values inline with `String.quoteMySQL` instead.
	@discardableResult
	func simpleQuery(_ sql: String) async throws -> [MySQLRow] {
		return try await self.withConnection { connection in
			try await connection.simpleQuery(sql).get()
		}
	}
}
