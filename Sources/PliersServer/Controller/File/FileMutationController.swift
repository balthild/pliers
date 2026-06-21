import Foundation
import Path
import PliersCommon
import Vapor
import VaporElementary

struct FileMutationController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("file").grouped(User.requireLoggedIn())
		group.post("create", use: self.create)
		group.post("update", use: self.update)
		group.post("delete", use: self.delete)
		group.post("chmod", use: self.chmod)
		group.post("chown", use: self.chown)
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		struct Input: Content {
			let filename: String
			let content: Data
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let dir: Path = try req.query["path"].expect("invalid path")
		guard try await dir.hasAccess(.rx, by: user.username) else {
			throw Abort(.notFound, reason: "invalid path or access denied")
		}

		let path = dir / input.filename
		if path.exists {
			throw Abort(.conflict, reason: "file already exists")
		}

		try await req.fileio.writeFile(ByteBuffer(data: input.content), at: path.string)

		return req.redirect(.back)
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		throw Abort(.notImplemented)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let path: Path = try req.query["path"].expect("invalid path")

		let dir = path.parent
		guard try await dir.hasAccess(.rx, by: user.username) else {
			throw Abort(.notFound, reason: "invalid path or access denied")
		}

		try path.delete()

		return req.redirect(.back)
	}

	@Sendable
	func chmod(req: Request) async throws -> Response {
		throw Abort(.notImplemented)
	}

	@Sendable
	func chown(req: Request) async throws -> Response {
		throw Abort(.notImplemented)
	}
}
