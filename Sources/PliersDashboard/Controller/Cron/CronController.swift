import Fluent
import Path
import PliersCommon
import Subprocess
import Vapor

struct CronController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.group("cron") { group in
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
		let jobs = try await user.$crons.get(on: req.db)

		return try await req.render {
			View.Page.CronListPage(jobs: jobs)
		}
	}

	@Sendable
	func new(req: Request) async throws -> Response {
		let model = Cron()

		return try await req.render {
			View.Page.CronNewPage(model: model)
		}
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let model = Cron()
		model.$user.id = try user.requireID()
		try Self.prepare(req: req, into: model)

		try await req.db.transaction { db in
			try await model.create(on: db)
			try await Self.apply(on: db, user: user)
		}

		return req.redirect(to: "/cron")
	}

	@Sendable
	func edit(req: Request) async throws -> Response {
		let model = try await Self.find(req: req)

		return try await req.render {
			View.Page.CronEditPage(model: model)
		}
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let model = try await Self.find(req: req)
		try Self.prepare(req: req, into: model)

		try await req.db.transaction { db in
			try await model.update(on: db)
			try await Self.apply(on: db, user: user)
		}

		return req.redirect(.back)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		struct Input: Content {
			let confirm: String
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let model = try await Self.find(req: req)

		guard input.confirm.lowercased() == model.id?.string else {
			throw AlertError("confirmation does not match the id")
		}

		try await req.db.transaction { db in
			try await model.delete(on: db)
			try await Self.apply(on: db, user: user)
		}

		return req.redirect(to: "/cron")
	}

	private static func find(req: Request) async throws -> Cron {
		let user = try req.auth.require(User.self)

		let model = try await req.find(Cron.self, "id")
		let owner = try await model.$user.get(on: req.db)

		guard try owner.isAdmin || owner.requireID() == user.requireID() else {
			throw Abort(.notFound)
		}

		return model
	}

	private static func prepare(req: Request, into model: Cron) throws {
		struct Input: Content {
			let expr: String
			let command: String
		}

		let input = try req.content.decode(Input.self)

		let expr = input.expr.trimmed
		let command = Crontab.normalize(command: input.command)

		guard !expr.isEmpty else {
			throw AlertError("expression is required")
		}

		guard !command.isEmpty else {
			throw AlertError("command is required")
		}

		model.expr = expr
		model.command = command
	}

	private static func apply(on database: any Database, user: User) async throws {
		let content = try await Self.build(on: database, user: user)
		try await Self.install(content, for: user.username)
	}

	private static func build(on database: any Database, user: User) async throws -> String {
		let jobs = try await user.$crons.get(on: database)

		let entries = jobs.map { Crontab.Entry(expr: $0.expr, command: $0.command) }
		let existing = try await Self.read(for: user.username)

		return Crontab.merge(into: existing, entries: entries)
	}

	private static func read(for username: String) async throws -> String {
		let result = try await Subprocess.run(
			.path(C.system.bin / "crontab"),
			arguments: ["-l"],
			environment: .custom([]),
			platformOptions: try .su(username),
			output: .string(limit: 1 << 20),
			error: .discarded,
		)

		guard result.terminationStatus.isSuccess else {
			// `crontab -l` exits non-zero when the user has no crontab yet.
			return ""
		}

		return result.standardOutput
	}

	private static func install(_ content: String, for username: String) async throws {
		let result = try await Subprocess.run(
			.path(C.system.bin / "crontab"),
			arguments: ["-"],
			environment: .custom([]),
			platformOptions: try .su(username),
			input: .string(content),
			output: .discarded,
			error: .string(limit: 8192),
		)

		guard result.terminationStatus.isSuccess else {
			let message = result.standardError.trimmed
			throw AlertError(message.isEmpty ? "failed to apply crontab" : message)
		}
	}
}
