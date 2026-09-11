import Testing

@testable import PliersDashboard

@Test func testPHPUnixAddress() throws {
	var config = PHP.Config()
	config.listen = .unix

	let version = try PHP.Version(parse: "8.4.24")

	#expect(
		Caddyfile.address(config.listen, version: version)
			== "unix//run/pliers/php/8.4.24/php-fpm.sock"
	)
}

@Test func testPHPTcpAddress() throws {
	var config = PHP.Config()
	config.listen = .tcp("127.0.0.1:9000")

	let version = try PHP.Version(parse: "8.4.24")

	#expect(
		Caddyfile.address(config.listen, version: version)
			== "127.0.0.1:9000"
	)
}
