import Fluent
import FluentSQLiteDriver
import JWT
import Path
import PliersCommon
import Vapor

extension PliersServer {
	func configure() async throws {
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
		let path = config.state / "db.sqlite"
		let config = DatabaseConfigurationFactory.sqlite(.file(path.string))
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
		try app.register(collection: FilesController())

		try app.register(collection: AuthController())
		try app.register(collection: TokenLoginController())
		try app.register(collection: PasskeyLoginController())
		try app.register(collection: PasswordLoginController())

		try app.register(collection: SettingsController())
		try app.register(collection: PasswordSettingsController())
	}
}
