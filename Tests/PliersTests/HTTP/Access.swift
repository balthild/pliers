import Fluent
import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

@Test func testUnauthenticatedRedirectsToLogin() async throws {
	try await withDashboard { app in
		try await app.testing().test(
			.GET,
			"/cron",
			headers: ["Host": "panel.example.com"],
		) { res in
			#expect(res.status == .seeOther)
			#expect(res.headers.first(name: .location)?.contains("/login") == true)
		}
	}
}

@Test func testNonAdminForbiddenFromUserRoutes() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		try await app.test(.GET, "/user", as: alice) { res in
			#expect(res.status == .forbidden)
		}
	}
}

@Test func testForeignCronIsNotFound() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		let bob = User()
		bob.username = "bob"
		bob.privileges = []
		try await bob.save(on: app.db)

		let cron = Cron()
		cron.expr = "*/5 * * * *"
		cron.command = "true"
		try await bob.$crons.create(cron, on: app.db)

		let id = try cron.requireID()
		try await app.test(.GET, "/cron/\(id)", as: alice) { res in
			#expect(res.status == .notFound)
		}
	}
}

@Test func testOwnCronIsAccessible() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		let cron = Cron()
		cron.expr = "*/5 * * * *"
		cron.command = "true"
		try await alice.$crons.create(cron, on: app.db)

		let id = try cron.requireID()
		try await app.test(.GET, "/cron/\(id)", as: alice) { res in
			#expect(res.status == .ok)
		}
	}
}

@Test func testAdminCanAccessForeignCron() async throws {
	try await withDashboard { app in
		let admin = User()
		admin.username = "operator"
		admin.privileges = [.admin]
		try await admin.save(on: app.db)

		let bob = User()
		bob.username = "bob"
		bob.privileges = []
		try await bob.save(on: app.db)

		let cron = Cron()
		cron.expr = "*/5 * * * *"
		cron.command = "true"
		try await bob.$crons.create(cron, on: app.db)

		let id = try cron.requireID()
		try await app.test(.GET, "/cron/\(id)", as: admin) { res in
			#expect(res.status == .ok)
		}
	}
}
