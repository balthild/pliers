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
		let username = NSUserName()
		let url = "http://localhost:\(context.config.port)/login/token?username=\(username)"
		let deadline = NIODeadline.now() + .seconds(5)
		let response = try await HTTPClient.shared.get(url: url, deadline: deadline).get()
		guard let body = response.body else {
			throw RuntimeError("failed to generate token")
		}

		let token = String(decoding: body.readableBytesView, as: UTF8.self)
		let nonce = SymmetricKey(size: .bits256).withUnsafeBytes({ $0.bcryptBase64String() })
		let full = "\(token);\(nonce)"

		let home = FileManager.default.homeDirectoryForCurrentUser
		let file = home.appending(path: Constants.userTokenPath)

		try FileManager.default.createDirectory(
			at: file.deletingLastPathComponent(),
			withIntermediateDirectories: true,
		)

		let created = FileManager.default.createFile(
			atPath: file.path,
			contents: Data(full.utf8),
			attributes: [.posixPermissions: 0o600],
		)

		if !created {
			throw RuntimeError("failed to write token file")
		}

		context.console.info("Login token generated. Note that it will expire soon.")
		context.console.print(full)
	}
}
