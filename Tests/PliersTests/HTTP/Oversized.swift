import Fluent
import NIOCore
import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

@Test func testOversizedUploadIsRejected() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		// `/file/create` collects at most 200mb, enforced while the body streams in, so the live
		// transport is required: the in-memory tester hands the handler a ready-made body.
		let oversized = ByteBuffer(bytes: [UInt8](repeating: 0x61, count: 201 * 1024 * 1024))

		try await app.test(
			.POST,
			"/file/create",
			as: alice,
			headers: [
				"Host": "panel.example.com",
				"Origin": "http://panel.example.com",
			],
			using: .running(hostname: "127.0.0.1", port: 0),
			body: oversized,
		) { res in
			#expect(res.status == .payloadTooLarge)
		}
	}
}
