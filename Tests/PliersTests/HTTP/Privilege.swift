import Fluent
import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

@Test func testOrdinaryUserForbiddenFromPrivilegedModules() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = []
		try await alice.save(on: app.db)

		for path in ["/caddy", "/php", "/mysql", "/user"] {
			try await app.test(.GET, path, as: alice) { res in
				#expect(res.status == .forbidden, "\(path) should be forbidden for an ordinary user")
			}
		}
	}
}

@Test func testForeignMySQLIsNotFound() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = [.mysql]
		try await alice.save(on: app.db)

		let bob = User()
		bob.username = "bob"
		bob.privileges = [.mysql]
		try await bob.save(on: app.db)

		let model = MySQL()
		model.database = "app"
		model.username = "app"
		try await bob.$mysqlDatabases.create(model, on: app.db)

		let id = try model.requireID()
		try await app.test(.GET, "/mysql/\(id)", as: alice) { res in
			#expect(res.status == .notFound)
		}
	}
}

@Test func testOwnMySQLIsAccessible() async throws {
	try await withDashboard { app in
		let alice = User()
		alice.username = "alice"
		alice.privileges = [.mysql]
		try await alice.save(on: app.db)

		let model = MySQL()
		model.database = "app"
		model.username = "app"
		try await alice.$mysqlDatabases.create(model, on: app.db)

		let id = try model.requireID()
		try await app.test(.GET, "/mysql/\(id)", as: alice) { res in
			#expect(res.status == .ok)
		}
	}
}
