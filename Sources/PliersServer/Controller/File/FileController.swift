import Foundation
import Path
import PliersCommon
import Vapor
import VaporElementary

struct FileController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("file").grouped(User.requireLoggedIn())
		group.get(use: self.index)
		group.get("download", use: self.download)
	}

	@Sendable
	func index(req: Request) async throws -> HTMLResponse {
		let user = try req.auth.require(User.self)
		let home = try Path.home(for: user.username).expect("get home directory")

		let path = try Path(req.query["path"] ?? home.string).expect("invalid path")

		if path.isDirectory {
			return try await self.list(req: req, path: path)
		} else {
			return try await self.edit(req: req, path: path)
		}
	}

	private func list(req: Request, path: Path) async throws -> HTMLResponse {
		let user = try req.auth.require(User.self)
		guard try await path.hasAccess(.rx, by: user.username) else {
			throw Abort(.notFound, reason: "not found or access denied")
		}

		let entries = try path.ls(.aUnsorted)
			.map { path in
				let attrs = try path.attrs.expect("get file attributes")
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

		return req.render {
			UI.Page.BrowseFile(
				path: path,
				entries: entries,
			)
		}
	}

	private func edit(req: Request, path: Path) async throws -> HTMLResponse {
		let user = try req.auth.require(User.self)
		guard try await path.hasAccess(.rw, by: user.username) else {
			throw Abort(.notFound, reason: "not found or access denied")
		}

		return req.render {
			"TODO"
		}
	}

	private func download(req: Request) async throws -> Response {
		let path: Path = try req.query["path"].expect("invalid path")

		let user = try req.auth.require(User.self)
		guard try await path.hasAccess(.r, by: user.username) else {
			throw Abort(.notFound, reason: "not found or access denied")
		}

		return try await req.fileio.asyncStreamFile(at: path.string)
	}
}
