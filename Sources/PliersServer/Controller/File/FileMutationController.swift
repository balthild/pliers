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
		throw Abort(.notImplemented)
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		throw Abort(.notImplemented)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		throw Abort(.notImplemented)
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
