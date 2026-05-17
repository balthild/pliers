import Fluent
import FluentSQLiteDriver
import Leaf
import Logging
import NIOCore
import NIOPosix
import NIOSSL
import Vapor

public enum PliersServer {
	public static func run() async throws {
		var env = Environment.production
		try LoggingSystem.bootstrap(from: &env)

		let app = try await Application.make(env)

		do {
			try await configure(app)
			try await app.execute()
			try await app.asyncShutdown()
		} catch {
			app.logger.report(error: error)
			try? await app.asyncShutdown()
			throw error
		}
	}

	private static func configure(_ app: Application) async throws {
		try environment(app)

		app.views.use(.leaf)
		try database(app)
		try http(app)
	}

	private static func environment(_ app: Application) throws {
		let names: Set<String> = [
			"UID", "GID", "EUID", "EGID",
			"HOME", "USER", "LOGNAME", "GROUPS",
			"SHELL", "SHLVL",
			"PATH",
			"TERM", "COLORTERM",
			"PWD", "OLDPWD",
			"LANG", "LANGUAGE",
			"HOSTNAME", "HOSTTYPE", "OSTYPE", "MACHTYPE",
		]

		let prefixes: [String] = ["LC_", "XDG_", "SUDO_"]
		let suffixes: [String] = ["_DIRECTORY"]

		for name in ProcessInfo.processInfo.environment.keys {
			if !names.contains(name)
				&& !prefixes.contains(where: { name.hasPrefix($0) })
				&& !suffixes.contains(where: { name.hasSuffix($0) })
			{
				unsetenv(name)
			}
		}
	}

	private static func database(_ app: Application) throws {
		let config = DatabaseConfigurationFactory.sqlite(.file("db.sqlite"))
		app.databases.use(config, as: .sqlite)

		app.migrations.add(CreateUser())
	}

	private static func http(_ app: Application) throws {
		app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

		try app.register(collection: HomeController())
		try app.register(collection: AuthController())
	}
}
