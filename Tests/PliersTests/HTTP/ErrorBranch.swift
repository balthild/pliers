import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

@Test func testUnknownRouteRendersHtmlErrorPageForBrowser() async throws {
	try await withDashboard { app in
		try await app.testing().test(
			.GET,
			"/no-such-route",
			headers: ["Accept": "text/html"],
		) { res in
			#expect(res.status == .notFound)
			#expect(res.headers.contentType?.type == "text")
		}
	}
}

@Test func testUnknownRouteReturnsAbortForApiClient() async throws {
	try await withDashboard { app in
		try await app.testing().test(
			.GET,
			"/no-such-route",
			headers: ["Accept": "application/json"],
		) { res in
			#expect(res.status == .notFound)
			#expect(res.headers.contentType?.type == "application")
		}
	}
}
