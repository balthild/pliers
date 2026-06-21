import Foundation
import Path
import PliersCommon
import Vapor
import VaporElementary

struct FileTransferController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("file").grouped(User.requireLoggedIn())
		group.get("download", use: self.download)
		group.post("upload", use: self.upload)
	}

	@Sendable
	func download(req: Request) async throws -> Response {
		throw Abort(.notImplemented)
	}

	@Sendable
	func upload(req: Request) async throws -> Response {
		throw Abort(.notImplemented)
	}
}
