import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

@Test func testStateChangingRequestWithoutOriginIsRejected() async throws {
	try await withDashboard { app in
		try await app.testing().test(
			.POST,
			"/login/password",
			headers: [
				"Host": "panel.example.com",
				"Content-Type": "application/x-www-form-urlencoded",
			],
			body: .init(string: "username=x"),
		) { res in
			#expect(res.status == .forbidden)
		}
	}
}

@Test func testStateChangingRequestWithSameOriginPasses() async throws {
	try await withDashboard { app in
		try await app.testing().test(
			.POST,
			"/login/password",
			headers: [
				"Host": "panel.example.com",
				"Origin": "http://panel.example.com",
				"Content-Type": "application/x-www-form-urlencoded",
			],
			body: .init(string: "username=x"),
		) { res in
			#expect(res.status != .forbidden)
		}
	}
}

@Test func testStateChangingRequestWithForeignOriginIsRejected() async throws {
	try await withDashboard { app in
		try await app.testing().test(
			.POST,
			"/login/password",
			headers: [
				"Host": "panel.example.com",
				"Origin": "https://evil.example.com",
				"Content-Type": "application/x-www-form-urlencoded",
			],
			body: .init(string: "username=x"),
		) { res in
			#expect(res.status == .forbidden)
		}
	}
}

@Test func testSessionCookieFlags() async throws {
	try await withDashboard { app in
		let cookie = app.sessions.configuration.cookieFactory(.init(string: "opaque"))
		#expect(cookie.isHTTPOnly)
		#expect(cookie.sameSite == .lax)
	}
}
