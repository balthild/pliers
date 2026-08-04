import Fluent
import FluentSQLiteDriver
import Path
import PliersCommon
import Vapor

extension PliersDashboard {
	func configure() async throws {
		try await database()
		try await console()
		try await http()

		app.placeholder = try .init(app: app)
		app.lifecycle.use(DBusServer())
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
		app.migrations.add(CreatePasskey())
		app.migrations.add(CreateCaddy())
		try await app.autoMigrate()
	}

	private func http() async throws {
		app.middleware.use(AlertMiddleware())
		app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

		app.sessions.configuration.cookieName = "pliers_session"
		app.sessions.use(.fluent)
		app.middleware.use(app.sessions.middleware)

		try app.register(collection: HomeController())

		try app.register(collection: AuthController())
		try app.register(collection: TokenLoginController())
		try app.register(collection: PasskeyLoginController())
		try app.register(collection: PasswordLoginController())

		try app.register(collection: SettingsController())
		try app.register(collection: PasskeySettingsController())
		try app.register(collection: PasswordSettingsController())

		try app.register(collection: FileController())
		try app.register(collection: FileMutationController())

		try app.register(collection: CaddyController())
		try app.register(collection: CaddyServiceController())
		try app.register(collection: CaddyConfigController())
	}
}
