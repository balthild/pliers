import Fluent
import PliersCommon
import Vapor
import VaporElementary

struct MySQLAccountController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.mysql))
			.group("mysql", "account") { group in
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
	func new(req: Request) async throws -> Response {
		let model = MySQLAccount()

		return try await req.render {
			View.Page.MySQLAccountNewPage(model: model)
		}
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		struct Input: Content {
			let username: String
			let host: String
			let password: String
		}

		let input = try req.content.decode(Input.self)
		let user = try req.auth.require(User.self)

		guard !input.password.isEmpty else {
			throw AlertError("password is required")
		}

		let model = MySQLAccount()
		try model.prepare(username: input.username, host: input.host)

		try await req.db.transaction { db in
			try await user.$mysqlAccounts.create(model, on: db)

			_ = try await rethrowing(alert: "failed to create mysql account") {
				// MySQL rejects `IDENTIFIED BY ?` as invalid syntax, so the password is embedded
				// as an escaped literal rather than bound.
				try await req.mysql.simpleQuery(
					"""
					CREATE USER \(model.quoteMySQL)
					IDENTIFIED BY \(input.password.quoteMySQL)
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
			View.Page.MySQLAccountEditPage(model: model)
		}
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		struct Input: Content {
			let password: String
		}

		let input = try req.content.decode(Input.self)
		let model = try await Self.find(req: req)

		if !input.password.isEmpty {
			try await rethrowing(alert: "failed to reset mysql account password") {
				_ = try await req.mysql.simpleQuery(
					"ALTER USER \(model.quoteMySQL) IDENTIFIED BY \(input.password.quoteMySQL)"
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

		let account = model.quoteMySQL

		try await req.db.transaction { db in
			try await model.delete(on: db)

			try await rethrowing(alert: "failed to delete mysql account") {
				_ = try await req.mysql.simpleQuery("DROP USER IF EXISTS \(account)")
			}
		}

		return req.redirect(to: "/mysql")
	}

	private static func find(req: Request) async throws -> MySQLAccount {
		let user = try req.auth.require(User.self)
		let model = try await req.find(MySQLAccount.self, "id")

		guard try user.isAdmin || model.$user.id == user.requireID() else {
			throw Abort(.notFound)
		}

		return model
	}
}
