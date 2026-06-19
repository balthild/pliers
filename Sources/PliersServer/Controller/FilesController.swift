import Foundation
import Vapor
import VaporElementary

struct FilesController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedIn()).get("files", use: self.index)
	}

	@Sendable
	func index(req: Request) async throws -> HTMLResponse {
		let user = try req.auth.require(User.self)
		let home = try FileManager.default.homeDirectory(forUser: user.username)
			.expect("get home directory")

		let path = req.query["path"] ?? home.path

		// TODO: check if user has access to the path

		var isDirectory: ObjCBool = false
		guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
			// TODO: display error message
			throw Abort(.notFound, reason: "path does not exist")
		}

		if isDirectory.boolValue {
			return try await self.browse(req: req, path: path)
		} else {
			return try await self.edit(req: req, path: path)
		}
	}

	private func browse(req: Request, path: String) async throws -> HTMLResponse {
		let dir = URL(filePath: path)

		let entries = try FileManager.default.contentsOfDirectory(atPath: path)
			.map { name in
				let url = dir.appendingPathComponent(name)

				let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
				let type = attrs[.type] as? FileAttributeType
				let owner = attrs[.ownerAccountName] as! String
				let mode = attrs[.posixPermissions] as! UInt16

				return (
					name: name,
					url: url,
					owner: owner,
					mode: mode,
					isDirectory: type == .typeDirectory,
					isSymlink: type == .typeSymbolicLink,
				)
			}
			.sorted {
				if $0.isDirectory != $1.isDirectory {
					return $0.isDirectory && !$1.isDirectory
				}

				return $0.name.localizedStandardCompare($1.name) == .orderedAscending
			}

		return req.render {
			UI.Page.BrowseFiles(
				path: path,
				entries: entries,
			)
		}
	}

	private func edit(req: Request, path: String) async throws -> HTMLResponse {
		return req.render {
			"TODO"
		}
	}
}
