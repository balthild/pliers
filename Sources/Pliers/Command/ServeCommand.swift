import ConsoleKit
import Glibc
import PliersServer
import Vapor

struct ServeCommand: AsyncCommand, Sendable {
	typealias Signature = Vapor::ServeCommand.Signature

	let help = "serve pliers over http"

	func run(using context: CommandContext, signature: Signature) async throws {
		let euid = geteuid()
		if euid != 0 {
			print("This program must be run as root.")
			exit(1)
		}

		let server = try await PliersServer.make(context, signature)
		try await server.run()
	}
}
