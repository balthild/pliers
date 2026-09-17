import Fluent
import Foundation
import PliersCommon
import Vapor
import VaporElementary

struct CaddyController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes
			.grouped(User.requireLoggedIn())
			.grouped(RequirePrivilegeMiddleware(.caddy))
			.group("caddy") { group in
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
		let sites = try await Caddy.query(on: req.db).all()

		let status = try await req.dbus.systemd.status("caddy.service")
			.alert("failed to get caddy service status")

		return try await req.render {
			View.Page.CaddyListPage(
				sites: sites,
				status: status,
			)
		}
	}

	@Sendable
	func new(req: Request) async throws -> Response {
		let model = Caddy()

		let phps = try await PHP.query(on: req.db).all()
			.sorted { $0.version < $1.version }

		return try await req.render {
			View.Page.CaddyNewPage(
				model: model,
				phps: phps,
			)
		}
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		let model = Caddy()

		try await Self.prepare(req: req, into: model)
		try await model.create(on: req.db)

		// this requires the model to have an ID
		try model.assignDefaultWebRoot()
		try await model.update(on: req.db)

		return req.redirect(to: "/caddy/\(try model.uuid)")
	}

	@Sendable
	func edit(req: Request) async throws -> Response {
		let model = try await req.find(Caddy.self, "id")

		let phps = try await PHP.query(on: req.db).all()
			.sorted { $0.version < $1.version }

		return try await req.render {
			View.Page.CaddyEditPage(
				model: model,
				phps: phps,
			)
		}
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		let model = try await req.find(Caddy.self, "id")

		try await Self.prepare(req: req, into: model)
		try model.assignDefaultWebRoot()
		try await model.update(on: req.db)

		return req.redirect(.back)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		struct Input: Content {
			let confirm: String
		}

		let input = try req.content.decode(Input.self)

		let model = try await req.find(Caddy.self, "id")

		guard input.confirm.lowercased() == model.id?.string else {
			throw AlertError("confirmation does not match the id")
		}

		try await model.delete(on: req.db)

		return req.redirect(to: "/caddy")
	}

	private static func prepare(req: Request, into model: Caddy) async throws {
		struct Input: Content {
			@Lines var domains: [String]
			let config: Caddy.Config
		}

		let input = try req.content.decode(Input.self)

		guard !input.domains.isEmpty else {
			throw AlertError("at least one domain is required")
		}

		let regex = /^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$/
		for domain in input.domains {
			guard domain.wholeMatch(of: regex) != nil else {
				throw AlertError("domain \(domain) is invalid")
			}
		}

		let existed: [Caddy]
		if let id = model.id {
			existed = try await Caddy.query(on: req.db).filter(\.$id != id).all()
		} else {
			existed = try await Caddy.query(on: req.db).all()
		}
		for domain in existed.flatMap({ $0.domains }) {
			guard !input.domains.contains(domain) else {
				throw AlertError("domain \(domain) is already in use")
			}
		}

		model.domains = input.domains
		model.config = input.config
		model.config.custom = input.config.custom
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}
}
