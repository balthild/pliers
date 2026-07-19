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
		group.post("mkdir", use: self.mkdir)
		group.post("create", use: self.create)
		group.post("update", use: self.update)
		group.post("delete", use: self.delete)
		group.post("chmod", use: self.chmod)
		group.post("unarchive", use: self.unarchive)
	}

	@Sendable
	func mkdir(req: Request) async throws -> Response {
		struct Input: Content {
			let directory: String
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let dir: Path = try req.query["path"].alert("invalid path")
		let path = dir / input.directory

		let result = PliersShim::create_dir(user.username, path.string)
		if result == EEXIST {
			throw AlertError("path already exists")
		} else if result != 0 {
			throw AlertError("invalid path or access denied")
		}

		return req.redirect(.back)
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		struct Input: Content {
			let filename: String
			let content: Data?
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let dir: Path = try req.query["path"].alert("invalid path")
		let path = dir / input.filename

		let result = PliersShim::create_file(user.username, path.string)
		if result == EEXIST {
			throw AlertError("path already exists")
		} else if result != 0 {
			throw AlertError("invalid path or access denied")
		}

		if let content = input.content {
			let buffer = req.byteBufferAllocator.buffer(data: content)
			try await req.fileio.fillFile(buffer, at: path.string)
		}

		return req.redirect(.back)
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		struct Input: Content {
			let content: String
		}

		let user = try req.auth.require(User.self)
		let input = try req.content.decode(Input.self)

		let path: Path = try req.query["path"].alert("invalid path")

		guard path.isFile && path.hasAccess(.rw, by: user.username) else {
			throw AlertError("invalid path or access denied")
		}

		let buffer = req.byteBufferAllocator.buffer(string: input.content)
		try await req.fileio.fillFile(buffer, at: path.string)

		return req.redirect(.back)
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

	@Sendable
	func unarchive(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let path: Path = try req.query["path"].alert("invalid path")

		guard path.isFile && path.hasAccess(.r, by: user.username) else {
			throw AlertError("invalid path or access denied")
		}
		guard path.parent.hasAccess(.wx, by: user.username) else {
			throw AlertError("invalid path or access denied")
		}

		let cmd = Constants.coreutils / "tar"
		let args = ["-xf", path.string]

		let result = try await Subprocess.run(
			.path(.init(cmd.string)),
			arguments: .init(.init(args)),
			environment: .custom([]),
			workingDirectory: .init(path.parent.string),
			platformOptions: try .su(user.username),
			output: .discarded,
			error: .string(limit: 8192, encoding: UTF8.self),
		)

		guard result.terminationStatus == .exited(0) else {
			throw AlertError(result.standardError ?? "unknown error")
		}

		return req.redirect(.back)
	}
}
