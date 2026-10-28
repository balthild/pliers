import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

@Test func testUnauthenticatedStateChangingRequestWithoutOriginIsForbidden() async throws {
	try await withDashboard { app in
		// the origin check runs before authentication, so a cross-site POST is rejected up front
		try await app.testing().test(
			.POST,
			"/logout",
			headers: ["Host": "panel.example.com"],
		) { res in
			#expect(res.status == .forbidden)
		}
	}
}

@Test func testUnauthenticatedStateChangingRequestWithSameOriginRedirectsToLogin() async throws {
	try await withDashboard { app in
		try await app.testing().test(
			.POST,
			"/logout",
			headers: [
				"Host": "panel.example.com",
				"Origin": "http://panel.example.com",
			],
		) { res in
			#expect(res.status == .seeOther)
			#expect(res.headers.first(name: .location)?.contains("/login") == true)
		}
	}
}
