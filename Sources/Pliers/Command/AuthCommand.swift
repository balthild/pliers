import AsyncHTTPClient
import ConsoleKit
import Crypto
import DBUS
import Glibc
import NIOCore
import Path
import PliersCommon
import PliersDBus
import PliersDashboard
import Vapor

struct AuthCommand: AsyncCommand, Sendable {
	struct Signature: CommandSignature {}

	let help = "generate a temporary login token"

	func run(using context: CommandContext, signature: Signature) async throws {
		let privkey = Curve25519.Signing.PrivateKey()
		let pubkey = privkey.publicKey.rawRepresentation.base64EncodedString()

		let challenge = try await DBusClient.system { connection in
			let proxy = ComBalthildPliersProxy(
				connection: connection,
				destination: "com.balthild.Pliers",
				path: "/com/balthild/Pliers",
			)

			let result = try await proxy.createLoginToken(pubkey: pubkey)

			return try Data(base64Encoded: result).alert("unknown error")
		}

		let signature = try privkey.signature(for: challenge).base64EncodedString()

		context.console.info("Login token generated. Note that it will expire soon.")
		context.console.print("\(pubkey);\(signature)")
	}
}
