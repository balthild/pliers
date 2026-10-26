import Path
import PliersCommon
import Testing

@Test func testConfigStoresValues() throws {
	let state = Path("/tmp")!
	let config = try Config(port: 7577, state: state)

	#expect(config.port == 7577)
	#expect(config.state.string == state.string)
	#expect(config.httpOrigins == [])
}

@Test func testConfigStoresHTTPOrigins() throws {
	let state = Path("/tmp")!
	let config = try Config(port: 7577, state: state, httpOrigins: ["https://panel.example.com"])

	#expect(config.httpOrigins == ["https://panel.example.com"])
}

@Test func testParseHTTPOrigins() {
	#expect(Config.parseHTTPOrigins(nil) == [])
	#expect(Config.parseHTTPOrigins("") == [])
	#expect(Config.parseHTTPOrigins("  ") == [])
	#expect(Config.parseHTTPOrigins(",,") == [])

	#expect(
		Config.parseHTTPOrigins("https://a.example.com, https://b.example.com:8443")
			== ["https://a.example.com", "https://b.example.com:8443"]
	)
	#expect(
		Config.parseHTTPOrigins(" https://a.example.com , ,")
			== ["https://a.example.com"]
	)
}

@Test func testConfigDefaultsTrustedProxies() throws {
	let state = Path("/tmp")!
	let config = try Config(port: 7577, state: state)

	#expect(config.trustedProxies == Config.defaultTrustedProxies)
}

@Test func testConfigStoresTrustedProxies() throws {
	let state = Path("/tmp")!
	let config = try Config(port: 7577, state: state, trustedProxies: ["10.0.0.0/8"])

	#expect(config.trustedProxies == ["10.0.0.0/8"])
}

@Test func testParseTrustedProxies() {
	#expect(Config.parseTrustedProxies(nil) == Config.defaultTrustedProxies)
	#expect(Config.parseTrustedProxies("") == Config.defaultTrustedProxies)
	#expect(Config.parseTrustedProxies("  ") == Config.defaultTrustedProxies)
	#expect(
		Config.parseTrustedProxies("10.0.0.0/8, 192.168.0.0/16")
			== ["10.0.0.0/8", "192.168.0.0/16"]
	)
}
