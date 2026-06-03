import ConsoleKit
import Glibc
import PliersCommon
import PliersServer
import Vapor

struct ServeCommand: AsyncCommand, Sendable {
	struct Signature: CommandSignature {}

	let help = "serve pliers over http"

	func run(using context: CommandContext, signature: Signature) async throws {
		let euid = geteuid()
		if euid != 0 {
			throw RuntimeError("the server must be run as root.")
		}

		let attrs = try FileManager.default.attributesOfItem(atPath: context.config.state.path)
		if attrs[.ownerAccountID] as? UInt32 != 0 {
			throw RuntimeError("state dir must be owned by root")
		}
		if attrs[.posixPermissions] as? UInt16 != 0o600 {
			throw RuntimeError("state dir must not be accessible by non-root users")
		}

		let server = try await PliersServer.make(context.config)
		try await server.run()
	}
}
