import Fluent
import Foundation
import PliersCommon
import Vapor
import VaporElementary

struct CaddyController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped(User.requireLoggedIn())

		group.group("caddy") { group in
			group.get(use: self.index)
			group.get("new", use: self.new)
			group.post("create", use: self.create)

			group.group(":id") { group in
				group.get(use: self.edit)
				group.post("update", use: self.update)
				// group.post("delete", use: self.delete)
			}
		}
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		let sites = try await Caddy.query(on: req.db).all()

		return try await req.render {
			View.Page.CaddyListPage(
				sites: sites
			)
		}
	}

	@Sendable
	func new(req: Request) async throws -> Response {
		let model = Caddy()

		return try await req.render {
			View.Page.CaddyNewPage(model: model)
		}
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		let model = Caddy()
		try await prepare(req: req, model: model)
		try await model.create(on: req.db)

		return req.redirect(to: "/caddy/\(try model.requireID())")
	}

	@Sendable
	func edit(req: Request) async throws -> Response {
		let model = try await req.find(Caddy.self, "id")

		return try await req.render {
			View.Page.CaddyEditPage(model: model)
		}
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		let model = try await req.find(Caddy.self, "id")

		try await prepare(req: req, model: model)
		try await model.update(on: req.db)

		return req.redirect(.back)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		let model = try await req.find(Caddy.self, "id")

		try await model.delete(on: req.db)

		return req.redirect(to: "/caddy")
	}

	private func prepare(req: Request, model: Caddy) async throws {
		struct Input: Content {
			@Lines var domains: [String]
			let config: Caddy.Config
		}

		let input = try req.content.decode(Input.self)

		guard !input.domains.isEmpty else {
			throw AlertError("at least one domain is required")
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
