import Fluent
import FluentSQLiteDriver
import Leaf
import Logging
import NIOCore
import NIOPosix
import NIOSSL
import Vapor

public struct PliersServer {
	private var context: CommandContext
	private var signature: ServeCommand.Signature

	private var app: Application { context.application }

	public static func make(
		_ context: CommandContext,
		_ signature: ServeCommand.Signature,
	) async throws -> Self {
		var env = Environment.production
		try LoggingSystem.bootstrap(from: &env)

		var context = context
		context.application = try await Application.make(env)

		return .init(
			context: context,
			signature: signature,
		)
	}

	public func run() async throws {
		do {
			try environment()
			try await configure()

			try await app.asyncBoot()
			try await execute()
			try await app.asyncShutdown()
		} catch {
			app.logger.report(error: error)
			try? await app.asyncShutdown()
			throw error
		}
	}

	private func environment() throws {
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

	private func execute() async throws {
		try await app.servers.asyncCommand.run(using: context, signature: signature)
		try await app.running?.onStop.get()
	}
}

extension PliersServer {
	private func configure() async throws {
		try await database()
		try await console()
		try await http()

		app.views.use(.leaf)

		// jwt is used for short-lived temporary login tokens only,
		// so the key can be randomly generated on each launch
		let key = SymmetricKey(size: .bits256)
		await app.jwt.keys.add(hmac: .init(key: key), digestAlgorithm: .sha256)
	}

	private func console() async throws {
		app.asyncCommands.commands.removeValue(forKey: "routes")
		app.asyncCommands.commands.removeValue(forKey: "migrate")
	}

	private func database() async throws {
		let config = DatabaseConfigurationFactory.sqlite(.file("db.sqlite"))
		app.databases.use(config, as: .sqlite)

		app.migrations.add(CreateUser())
	}

	private func http() async throws {
		app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

		app.sessions.configuration.cookieName = "pliers_session"
		app.middleware.use(app.sessions.middleware)

		try app.register(collection: HomeController())
		try app.register(collection: LoginController())
	}
}
