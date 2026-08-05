import Crypto
import DBUS
import Glibc
import PliersCommon
import PliersDBus
import Vapor

struct DBusHandler: ComBalthildPliersHandler {
	@TaskLocal
	static var sender: UInt32?

	let app: Application

	func createLoginToken(pubkey: [UInt8]) async throws -> [UInt8] {
		let uid = try Self.sender.alert("unknown error")
		let pw = try getpwuid(uid).alert("unknown error")

		let pubkey = try Curve25519.Signing.PublicKey(rawRepresentation: pubkey)
		let challenge = SymmetricKey(size: .bits256).withUnsafeBytes { [UInt8]($0) }

		let username = String(cString: pw.pointee.pw_name)
		let user = try await User.findOrCreate(username: username, on: app.db)

		user.token = .init()
		user.token!.pubkey = pubkey.rawRepresentation
		user.token!.challenge = Data(challenge)
		user.token!.expiration = .now + 300
		try await user.save(on: app.db)

		return challenge
	}
}
