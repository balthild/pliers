import Testing

@testable import PliersDashboard

@Test func testQuoteMySQLBuildsAccountName() {
	let model = MySQLAccount()
	model.username = "app"
	model.host = "localhost"

	#expect(model.quoteMySQL == "'app'@'localhost'")
}

@Test func testQuoteMySQLAllowsWildcardHost() {
	let model = MySQLAccount()
	model.username = "app"
	model.host = "%"

	#expect(model.quoteMySQL == "'app'@'%'")
}

@Test func testPrepareTrimsAndAssigns() throws {
	let model = MySQLAccount()

	try model.prepare(username: "  app  ", host: " localhost ")

	#expect(model.username == "app")
	#expect(model.host == "localhost")
}

@Test func testPrepareAllowsInteriorSeparators() throws {
	let model = MySQLAccount()

	try model.prepare(username: "my-app.v2", host: "localhost")

	#expect(model.username == "my-app.v2")
}

@Test func testPrepareRejectsInvalidUsername() {
	let model = MySQLAccount()

	for username in ["app'--", "", "-app", ".app"] {
		#expect(throws: (any Error).self) {
			try model.prepare(username: username, host: "localhost")
		}
	}
}

@Test func testPrepareRejectsInvalidHost() {
	let model = MySQLAccount()

	#expect(throws: (any Error).self) {
		try model.prepare(username: "app", host: "local host")
	}
	#expect(throws: (any Error).self) {
		try model.prepare(username: "app", host: "")
	}
}
