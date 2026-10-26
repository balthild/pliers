import PliersCommon
import Testing

@testable import PliersDashboard

@Test func testQuoteCaddyWrapsValue() throws {
	let path = try "/var/www/example.com/public".quoteCaddy
	#expect(path == "`/var/www/example.com/public`")

	let upstream = try "127.0.0.1:9000".quoteCaddy
	#expect(upstream == "`127.0.0.1:9000`")
}

@Test func testQuoteCaddyAllowsEmptyAndSpace() throws {
	let empty = try "".quoteCaddy
	#expect(empty == "``")

	let spaced = try "It works!".quoteCaddy
	#expect(spaced == "`It works!`")
}

@Test func testQuoteCaddyAllowsNonASCII() throws {
	let value = try "café".quoteCaddy
	#expect(value == "`café`")
}

@Test func testQuoteCaddyRejectsBacktick() {
	#expect(throws: AlertError.self) { try "a`b".quoteCaddy }
	#expect(throws: AlertError.self) { try "`".quoteCaddy }
}

@Test func testQuoteCaddyRejectsControlCharacters() {
	for value in ["a\nb", "a\rb", "a\tb", "a\0b", "a\u{7f}b", "a\u{01}b", "a\u{1f}b"] {
		#expect(throws: AlertError.self) { try value.quoteCaddy }
	}
}

@Test func testQuoteCaddyRejectsDirectiveInjection() {
	let injected = "/var/log/caddy/site.log\nheader X-Injected true"
	#expect(throws: AlertError.self) { try injected.quoteCaddy }
}
