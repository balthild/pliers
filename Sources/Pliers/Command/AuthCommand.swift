import AsyncHTTPClient
import ConsoleKit
import Glibc
import NIOCore
import PliersCommon
import PliersServer
import Vapor

struct AuthCommand: AsyncCommand, Sendable {
	struct Signature: CommandSignature {}

	let help = "generate a temporary login token"

	func run(using context: CommandContext, signature: Signature) async throws {
		let url = "http://localhost:8080/login/token"
		let deadline = NIODeadline.now() + .seconds(5)
		let response = try await HTTPClient.shared.get(url: url, deadline: deadline).get()
		guard let body = response.body else {
			throw RuntimeError("failed to generate token")
		}

		let token = String(decoding: body.readableBytesView, as: UTF8.self)

		let home = FileManager.default.homeDirectoryForCurrentUser
		let file = home.appending(path: ".config/pliers/token")

		try FileManager.default.createDirectory(
			at: file.deletingLastPathComponent(),
			withIntermediateDirectories: true,
		)

		let attrs: [FileAttributeKey: Any] = [.posixPermissions: 0o600]
		let created = FileManager.default.createFile(
			atPath: file.path,
			contents: Data(token.utf8),
			attributes: attrs,
		)

		if !created {
			throw RuntimeError("failed to write token file")
		}

		context.console.info("Login token generated. Note that it will expire soon.")
		context.console.print(token)
	}
}
