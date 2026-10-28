import Fluent
import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

@Test func testLogoutDestroysSession() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		let key = try await app.login(alice)

		// a state-changing request still has to pass the origin check
		try await app.testing().test(
			.POST,
			"/logout",
			headers: [
				"Cookie": "pliers_session=\(key)",
				"Host": "panel.example.com",
				"Origin": "http://panel.example.com",
			],
		) { res in
			#expect(res.status == .seeOther)
		}

		// the server-side session record must be gone
		let remaining = try await SessionRecord.query(on: app.db)
			.filter(\.$key == .init(string: key))
			.count()
		#expect(remaining == 0)
	}
}
