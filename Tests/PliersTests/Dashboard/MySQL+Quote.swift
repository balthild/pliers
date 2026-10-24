import Testing

@testable import PliersDashboard

@Test func testQuoteDatabaseUsesBackticks() {
	let model = MySQL()
	model.database = "app"

	#expect(model.quoteDatabase == "`app`")
}

@Test func testQuoteAccountBuildsName() {
	let model = MySQL()
	model.username = "app"
	model.host = "localhost"

	#expect(model.quoteAccount == "'app'@'localhost'")
}

@Test func testQuoteAccountAllowsWildcardHost() {
	let model = MySQL()
	model.username = "app"
	model.host = "%"

	#expect(model.quoteAccount == "'app'@'%'")
}

@Test func testPrepareTrimsAndAssigns() throws {
	let model = MySQL()

	try model.prepare(database: "  app  ", username: " user ", host: " localhost ")

	#expect(model.database == "app")
	#expect(model.username == "user")
	#expect(model.host == "localhost")
}

@Test func testPrepareAllowsInteriorSeparators() throws {
	let model = MySQL()

	try model.prepare(database: "my-app.v2", username: "my-app.v2", host: "localhost")

	#expect(model.database == "my-app.v2")
	#expect(model.username == "my-app.v2")
}

@Test func testPrepareRejectsInvalidDatabase() {
	let model = MySQL()

	for database in ["app'--", "", "-app", ".app"] {
		#expect(throws: (any Error).self) {
			try model.prepare(database: database, username: "app", host: "localhost")
		}
	}
}

@Test func testPrepareRejectsInvalidUsername() {
	let model = MySQL()

	for username in ["app'--", "", "-app", ".app"] {
		#expect(throws: (any Error).self) {
			try model.prepare(database: "app", username: username, host: "localhost")
		}
	}
}

@Test func testPrepareRejectsInvalidHost() {
	let model = MySQL()

	#expect(throws: (any Error).self) {
		try model.prepare(database: "app", username: "app", host: "local host")
	}
	#expect(throws: (any Error).self) {
		try model.prepare(database: "app", username: "app", host: "")
	}
}
