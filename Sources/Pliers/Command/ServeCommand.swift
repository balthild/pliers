import ConsoleKit
import Glibc
import Path
import PliersCommon
import PliersDashboard
import Vapor

struct ServeCommand: AsyncCommand, Sendable {
	struct Signature: CommandSignature {}

	let help = "serve pliers dashboard over http"

	func run(using context: CommandContext, signature: Signature) async throws {
		let euid = geteuid()
		if euid != 0 {
			throw RuntimeError("the server must be run as root.")
		}

		try context.config.state.mkdir(.p)

		let attrs = try context.config.state.attrs.expect("read state dir attributes")
		guard let owner = attrs[.ownerAccountID] as? UInt32, owner == 0 else {
			throw RuntimeError("state dir must be owned by root")
		}
		guard let mode = attrs[.posixPermissions] as? UInt16, mode & 0o077 == 0 else {
			throw RuntimeError("state dir must not be accessible by non-root users")
		}

		let server = try await PliersDashboard.make(context.config)
		try await server.run()
	}
}
