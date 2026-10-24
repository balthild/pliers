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

	try model.prepare(
		database: "  app  ",
		username: " user ",
		host: " localhost ",
		charset: " latin1 ",
	)

	#expect(model.database == "app")
	#expect(model.username == "user")
	#expect(model.host == "localhost")
	#expect(model.charset == .latin1)
}

@Test func testDefaultCharsetIsUtf8mb4() {
	#expect(MySQL().charset == .utf8mb4)
}

@Test func testPrepareRejectsInvalidCharset() {
	let model = MySQL()

	for charset in ["", "utf8; DROP DATABASE x", "utf8mb5"] {
		#expect(throws: (any Error).self) {
			try model.prepare(database: "app", username: "app", host: "localhost", charset: charset)
		}
	}
}

@Test func testPrepareAllowsInteriorSeparators() throws {
	let model = MySQL()

	try model.prepare(
		database: "my-app.v2",
		username: "my-app.v2",
		host: "localhost",
		charset: "utf8mb4",
	)

	#expect(model.database == "my-app.v2")
	#expect(model.username == "my-app.v2")
}

@Test func testPrepareRejectsInvalidDatabase() {
	let model = MySQL()

	for database in ["app'--", "", "-app", ".app"] {
		#expect(throws: (any Error).self) {
			try model.prepare(database: database, username: "app", host: "localhost", charset: "utf8mb4")
		}
	}
}

@Test func testPrepareRejectsInvalidUsername() {
	let model = MySQL()

	for username in ["app'--", "", "-app", ".app"] {
		#expect(throws: (any Error).self) {
			try model.prepare(database: "app", username: username, host: "localhost", charset: "utf8mb4")
		}
	}
}

@Test func testPrepareRejectsInvalidHost() {
	let model = MySQL()

	#expect(throws: (any Error).self) {
		try model.prepare(database: "app", username: "app", host: "local host", charset: "utf8mb4")
	}
	#expect(throws: (any Error).self) {
		try model.prepare(database: "app", username: "app", host: "", charset: "utf8mb4")
	}
}
