import Foundation
import Glibc
import Path
import PliersCommon
import PliersShim
import Subprocess
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

		let dir: Path = try req.query["path"].alert("invalid path")
		let path = dir / input.filename

		let result = PliersShim::create_file(user.username, path.string)
		if result == EEXIST {
			throw AlertError("file already exists")
		} else if result != 0 {
			throw AlertError("invalid path or access denied")
		}

		let buffer = req.byteBufferAllocator.buffer(data: input.content)
		try await req.fileio.fillFile(buffer, at: path.string)

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

		let path: Path = try req.query["path"].alert("invalid path")

		guard input.confirm == path.string else {
			throw AlertError("confirmation does not match the file path")
		}

		let cmd = Constants.coreutils / "rm"
		let args = ["-rf", path.string]

		let result = try await Subprocess.run(
			.path(.init(cmd.string)),
			arguments: .init(.init(args)),
			environment: .custom([]),
			platformOptions: try .su(user.username),
			output: .discarded,
		)

		guard result.terminationStatus == .exited(0) else {
			throw AlertError("invalid path or access denied")
		}

		return req.redirect(.back)
	}

	@Sendable
	func chmod(req: Request) async throws -> Response {
		struct Input: Content {
			let mode: String
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let path: Path = try req.query["path"].alert("invalid path")

		guard let mode = UInt32(input.mode, radix: 8), mode >= 0 && mode <= 0o777 else {
			throw AlertError("invalid mode number")
		}

		let result = PliersShim::change_mode(user.username, path.string, mode)
		if result != 0 {
			throw AlertError("invalid path or access denied")
		}

		return req.redirect(.back)
	}
}
