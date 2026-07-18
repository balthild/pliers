import Foundation
import Path
import PliersCommon
import Vapor
import VaporElementary

struct FileController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("file").grouped(User.requireLoggedIn())
		group.get(use: self.index)
		group.get("edit", use: self.edit)
		group.get("download", use: self.download)
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)
		let home = try Path.home(for: user.username).alert("failed to get home directory")

		let path = try Path(req.query["path"] ?? home.string).alert("invalid path")

		guard path.isDirectory && path.hasAccess(.rx, by: user.username) else {
			throw AlertError("invalid path or access denied")
		}

		let entries = try path.ls(.aUnsorted)
			.map { path in
				let attrs = try path.attrs.alert("failed to get file attributes")
				let owner = attrs[.ownerAccountName] as! String
				let mode = attrs[.posixPermissions] as! UInt16

				return (
					name: path.basename(),
					path: path,
					dir: path.isDirectory,
					owner: owner,
					mode: mode,
				)
			}
			.sorted {
				if $0.path.isDirectory != $1.path.isDirectory {
					return $0.path.isDirectory && !$1.path.isDirectory
				}

				return $0.name.localizedStandardCompare($1.name) == .orderedAscending
			}

		return try await req.render {
			View.Page.FileListPage(
				path: path,
				entries: entries,
			)
		}
	}

	private func edit(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		let path: Path = try req.query["path"].alert("invalid path")

		guard path.isFile && path.hasAccess(.rw, by: user.username) else {
			throw AlertError("invalid path or access denied")
		}

		var buffer = try await req.fileio.collectFile(at: path.string)
		guard let text = buffer.readString(length: buffer.readableBytes) else {
			throw AlertError("not a utf-8 text file")
		}

		return try await req.render {
			View.Page.FileEditPage(
				path: path,
				text: text,
			)
		}
	}

	private func download(req: Request) async throws -> Response {
		let path: Path = try req.query["path"].alert("invalid path")

		let user = try req.auth.require(User.self)
		guard path.hasAccess(.r, by: user.username) else {
			throw AlertError("invalid path or access denied")
		}

		return try await req.fileio.asyncStreamFile(at: path.string)
	}
}
