import Fluent
import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

// The live transport is used because the in-memory tester sets `remoteAddress` to nil, so
// `TrustedProxiesMiddleware` could never trust the peer and `X-Forwarded-Proto` would be ignored.

@Test func testSessionCookieIsSecureOverHttps() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		try await app.test(
			.GET,
			"/cron",
			as: alice,
			scheme: "https",
			using: .running(hostname: "127.0.0.1", port: 0),
		) { res in
			let cookie = res.headers.first(name: "Set-Cookie") ?? ""
			#expect(cookie.contains("pliers_session="))
			#expect(cookie.contains("HttpOnly"))
			#expect(cookie.contains("Secure"))
		}
	}
}

@Test func testSessionCookieIsNotSecureOverHttp() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		try await app.test(
			.GET,
			"/cron",
			as: alice,
			scheme: "http",
			using: .running(hostname: "127.0.0.1", port: 0),
		) { res in
			let cookie = res.headers.first(name: "Set-Cookie") ?? ""
			#expect(cookie.contains("pliers_session="))
			#expect(cookie.contains("Secure") == false)
		}
	}
}
