import Testing

@testable import PliersDashboard

@Test func testCaddyfileUnixAddress() throws {
	let model = PHP()
	model.version = try PHP.Version(parse: "8.4.24")
	model.config = PHP.Config()
	model.config.listen = .unix

	#expect(
		model.config.caddyListenAddress(version: model.version)
			== "unix//run/pliers/php/8.4.24/php-fpm.sock"
	)
}

@Test func testCaddyfileTcpAddress() throws {
	let model = PHP()
	model.version = try PHP.Version(parse: "8.4.24")
	model.config = PHP.Config()
	model.config.listen = .tcp("127.0.0.1:9000")

	#expect(
		model.config.caddyListenAddress(version: model.version)
			== "tcp/127.0.0.1:9000"
	)
}

@Test func testConfigUnixAddress() throws {
	let model = PHP()
	model.version = try PHP.Version(parse: "8.4.24")
	model.config = PHP.Config()
	model.config.listen = .unix

	#expect(
		model.config.rawListenAddress(version: model.version)
			== "/run/pliers/php/8.4.24/php-fpm.sock"
	)
}

@Test func testConfigTcpAddress() throws {
	let model = PHP()
	model.version = try PHP.Version(parse: "8.4.24")
	model.config = PHP.Config()
	model.config.listen = .tcp("127.0.0.1:9000")

	#expect(
		model.config.rawListenAddress(version: model.version)
			== "127.0.0.1:9000"
	)
}
