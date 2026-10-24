import Fluent
import PliersCommon
import Vapor
import VaporElementary

struct MySQLController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.mysql))
			.group("mysql") { group in
				group.get(use: self.index)
				group.get("new", use: self.new)
				group.post("create", use: self.create)

				group.group(":id") { group in
					group.get(use: self.edit)
					group.post("update", use: self.update)
					group.post("delete", use: self.delete)
				}
			}
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let users: [UUID: User]
		if user.isAdmin {
			users = try await User.query(on: req.db).all()
				.keyed { try $0.requireID() }
		} else {
			users = [:]
		}

		let owner: User?
		if user.isAdmin, let id: UUID = req.query["user"] {
			owner = users[id]
		} else {
			owner = user
		}

		let databases = try await owner?.$mysqlDatabases.get(on: req.db) ?? []

		let status = try await req.dbus.systemd.status(C.mysql.service)
			.alert("failed to get mysql service status")

		return try await req.render {
			View.Page.MySQLPage(
				status: status,
				users: users,
				owner: owner,
				databases: databases,
			)
		}
	}

	@Sendable
	func new(req: Request) async throws -> Response {
		let model = MySQL()

		return try await req.render {
			View.Page.MySQLNewPage(model: model)
		}
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		struct Input: Content {
			let database: String
			let username: String
			let host: String
			let charset: String
			let password: String
		}

		let input = try req.content.decode(Input.self)
		let user = try req.auth.require(User.self)

		guard !input.password.isEmpty else {
			throw AlertError("password is required")
		}

		let model = MySQL()
		try model.prepare(
			database: input.database,
			username: input.username,
			host: input.host,
			charset: input.charset,
		)

		try await req.db.transaction { db in
			try await user.$mysqlDatabases.create(model, on: db)

			// Every statement either succeeds or throws, rolling the local row back with it.
			try await rethrowing(alert: "failed to create mysql database") {
				_ = try await req.mysql.simpleQuery(
					"""
					CREATE DATABASE \(model.quoteDatabase)
					CHARACTER SET \(model.charset.rawValue)
					"""
				)
			}

			// MySQL rejects `IDENTIFIED BY ?` as invalid syntax, so the password is embedded as
			// an escaped literal rather than bound.
			try await rethrowing(alert: "failed to create mysql user") {
				_ = try await req.mysql.simpleQuery(
					"""
					CREATE USER \(model.quoteAccount)
					IDENTIFIED BY \(input.password.quoteMySQL)
					"""
				)
			}

			try await rethrowing(alert: "failed to grant mysql privileges") {
				_ = try await req.mysql.simpleQuery(
					"""
					GRANT ALL PRIVILEGES
					ON \(model.quoteDatabase).*
					TO \(model.quoteAccount)
					"""
				)
			}
		}

		return req.redirect(to: "/mysql")
	}

	@Sendable
	func edit(req: Request) async throws -> Response {
		let model = try await Self.find(req: req)

		return try await req.render {
			View.Page.MySQLEditPage(model: model)
		}
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		struct Input: Content {
			let password: String
		}

		let input = try req.content.decode(Input.self)
		let model = try await Self.find(req: req)

		// The database name and user are immutable once created, so only the password can change.
		if !input.password.isEmpty {
			try await rethrowing(alert: "failed to reset mysql password") {
				_ = try await req.mysql.simpleQuery(
					"""
					ALTER USER \(model.quoteAccount)
					IDENTIFIED BY \(input.password.quoteMySQL)
					"""
				)
			}
		}

		return req.redirect(.back)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		struct Input: Content {
			let confirm: String
		}

		let input = try req.content.decode(Input.self)
		let model = try await Self.find(req: req)

		guard input.confirm.lowercased() == model.id?.string else {
			throw AlertError("confirmation does not match the id")
		}

		let database = model.quoteDatabase
		let account = model.quoteAccount

		try await req.db.transaction { db in
			try await model.delete(on: db)

			try await rethrowing(alert: "failed to delete mysql database") {
				_ = try await req.mysql.simpleQuery("DROP DATABASE IF EXISTS \(database)")
				_ = try await req.mysql.simpleQuery("DROP USER IF EXISTS \(account)")
			}
		}

		return req.redirect(to: "/mysql")
	}

	private static func find(req: Request) async throws -> MySQL {
		let user = try req.auth.require(User.self)
		let model = try await req.find(MySQL.self, "id")

		guard try user.isAdmin || model.$user.id == user.requireID() else {
			throw Abort(.notFound)
		}

		return model
	}
}
