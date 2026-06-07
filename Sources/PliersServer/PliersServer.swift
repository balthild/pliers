import Fluent
import FluentSQLiteDriver
import JWT
import Logging
import NIOCore
import NIOPosix
import NIOSSL
import PliersCommon
import Vapor

public struct PliersServer {
	private let config: Config
	private let app: Application

	public static func make(_ config: Config) async throws -> Self {
		var env = Environment.production
		try LoggingSystem.bootstrap(from: &env)

		let app = try await Application.make(env)

		return .init(
			config: config,
			app: app,
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
		let input = CommandInput(arguments: ["serve", "--port", String(config.port)])
		var context = CommandContext(console: Terminal(), input: input)
		context.application = app

		try await app.servers.asyncCommand.run(using: &context)
		try await app.running?.onStop.get()
	}
}

extension PliersServer {
	private func configure() async throws {
		try await database()
		try await console()
		try await http()

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
		let file = config.state.appending(path: "db.sqlite")
		let config = DatabaseConfigurationFactory.sqlite(.file(file.path))
		app.databases.use(config, as: .sqlite)

		app.migrations.add(SessionRecord.migration)
		app.migrations.add(CreateUser())
		try await app.autoMigrate()
	}

	private func http() async throws {
		app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

		app.sessions.configuration.cookieName = "pliers_session"
		app.sessions.use(.fluent)
		app.middleware.use(app.sessions.middleware)

		try app.register(collection: HomeController())

		try app.register(collection: AuthController())
		try app.register(collection: TokenLoginController())
		try app.register(collection: PasskeyLoginController())
		try app.register(collection: PasswordLoginController())

		try app.register(collection: DashboardController())
	}
}
