import Foundation
import Path
import PliersCommon
import Vapor
import VaporElementary

struct FileController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedIn()).get("file", use: self.index)
	}

	@Sendable
	func index(req: Request) async throws -> HTMLResponse {
		let user = try req.auth.require(User.self)
		let home = try Path.home(for: user.username).expect("get home directory")

		let path = try Path(req.query["path"] ?? home.string).expect("resolve path")
		guard try await path.hasAccess(.rx, by: user.username) else {
			throw Abort(.notFound, reason: "path not exist or access denied")
		}

		if path.isDirectory {
			return try await self.browse(req: req, path: path)
		} else {
			return try await self.edit(req: req, path: path)
		}
	}

	private func browse(req: Request, path: Path) async throws -> HTMLResponse {
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
		return req.render {
			"TODO"
		}
	}
}
