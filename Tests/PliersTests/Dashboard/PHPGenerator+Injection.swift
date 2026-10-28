import Foundation
import Path
import Testing

@testable import PliersDashboard

private let listenCorpus: [String] = [
	"127.0.0.1:9000",
	"0.0.0.0:9000",
	"127.0.0.1:9000\nuser = root",
	"127.0.0.1:9000\r\n",
	"127.0.0.1:9000\0",
	"127.0.0.1:9000\n\npm = static",
	"[::1]:9000",
	"127.0.0.1:99999",
	"127.0.0.1:0",
	"unix//run/x.sock",
]

private let sizeCorpus: [String] = [
	"128M",
	"2G",
	"512k",
	"0",
	"-1",
	"128M\npost_max_size = 1G",
	"128M\rmemory_limit = -1",
	"128 M",
	"128MB",
	"1.5G",
]

@Test func testPHPListenStructurePreserved() throws {
	let version = try PHP.Version(parse: "8.4.23")
	let configurator = PHPConfigurator(version: version)

	var baselineConfig = PHP.Config()
	baselineConfig.listen = .tcp("127.0.0.1:9000")
	let baselineLines = configurator.buildFPM(config: baselineConfig).components(separatedBy: "\n")
		.count

	for value in listenCorpus where value.isPHPListenAddress {
		var config = PHP.Config()
		config.listen = .tcp(value)
		let text = configurator.buildFPM(config: config)

		// an accepted address must not add or remove a line
		#expect(text.components(separatedBy: "\n").count == baselineLines)
		#expect(text.contains("listen = \(value)"))
	}
}

@Test func testPHPSizeStructurePreserved() throws {
	let version = try PHP.Version(parse: "8.4.23")
	let configurator = PHPConfigurator(version: version)

	let baselineLines = configurator.buildINI(config: PHP.Config()).components(separatedBy: "\n")
		.count

	for value in sizeCorpus where value.isPHPSizeValue {
		var config = PHP.Config()
		config.memoryLimit = value
		let text = configurator.buildINI(config: config)

		#expect(text.components(separatedBy: "\n").count == baselineLines)
		#expect(text.contains("memory_limit = \(value)"))
	}
}

@Test func testPHPGeneratorValidatesWithRealParser() async throws {
	let version = try PHP.Version(parse: "8.4.23")
	let configurator = PHPConfigurator(version: version)

	guard FileManager.default.isExecutableFile(atPath: configurator.binary.string) else {
		return
	}

	for value in listenCorpus where value.isPHPListenAddress {
		var config = PHP.Config()
		config.listen = .tcp(value)

		let dir = try Path.mktemp()
		try configurator.buildFPM(config: config)
			.write(toFile: (dir / "php-fpm.conf").string, atomically: true, encoding: .utf8)
		try configurator.buildINI(config: config)
			.write(toFile: (dir / "php.ini").string, atomically: true, encoding: .utf8)

		// reuses the production validator; it throws when php-fpm rejects the config
		try await PHPController.validate(tmp: dir, configurator: configurator)
		try? dir.delete()
	}
}

@Test func testUnvalidatedPHPListenIsVulnerable() {
	// the naive path (interpolating without `isPHPListenAddress`) writes a second directive line
	let injected = "listen = 127.0.0.1:9000\nuser = root"
	#expect(injected.components(separatedBy: "\n").count == 2)

	#expect("127.0.0.1:9000\nuser = root".isPHPListenAddress == false)
}
