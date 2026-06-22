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
		// TODO: do no check access as it's unreliable. just run the operation as the user
		guard try await dir.hasAccess(.wx, by: user.username) else {
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
		struct Input: Content {
			let confirm: String
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let path: Path = try req.query["path"].expect("invalid path")

		guard input.confirm == path.string else {
			throw Abort(.badRequest, reason: "confirmation does not match the file path")
		}

		let dir = path.parent
		// TODO: do no check access as it's unreliable. just run the operation as the user
		guard try await dir.hasAccess(.wx, by: user.username) else {
			throw Abort(.notFound, reason: "invalid path or access denied")
		}

		try path.delete()

		return req.redirect(.back)
	}

	@Sendable
	func chmod(req: Request) async throws -> Response {
		struct Input: Content {
			let mode: String
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let path: Path = try req.query["path"].expect("invalid path")

		guard let mode = Int(input.mode, radix: 8), mode >= 0 && mode <= 0o777 else {
			throw Abort(.badRequest, reason: "invalid mode")
		}

		if user.username != "root" {
			let attrs = try path.attrs.expect("read file attributes")
			let owner = attrs[.ownerAccountName] as? String
			guard owner == user.username else {
				throw Abort(.notFound, reason: "invalid path or access denied")
			}
		}

		try path.chmod(mode)

		return req.redirect(.back)
	}
}
