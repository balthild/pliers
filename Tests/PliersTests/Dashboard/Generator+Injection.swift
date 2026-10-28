import Foundation
import Path
import PliersCommon
import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

/// Adversarial values fed to the generators: injection attempts plus benign edge cases.
private let corpus: [String] = [
	"127.0.0.1:9000",
	"café.example.com",
	"127.0.0.1:9000\nreverse_proxy evil.local",
	"127.0.0.1:9000\r\nheader X-Evil 1",
	"a\rb",
	"a\tb",
	"a\0b",
	"a`b",
	"`",
	"127.0.0.1:9000 { }",
	#""quoted""#,
	"127.0.0.1:9000 # comment",
	String(repeating: "a", count: 5000),
]

@Test func testQuoteCaddyCorpusInvariant() {
	for value in corpus {
		let quoted: String
		do {
			quoted = try value.quoteCaddy
		} catch {
			// an unsafe value is rejected, which is the expected outcome
			continue
		}

		// accepted values must stay a single, balanced backtick token
		#expect(!quoted.contains("\n"))
		#expect(!quoted.contains("\r"))
		#expect(quoted.count(where: { $0 == "`" }) == 2)
	}
}

@Test func testCaddyfileStructurePreserved() async throws {
	guard FileManager.default.isExecutableFile(atPath: C.caddy.exec.string) else {
		return
	}

	try await withApp { app in
		for value in corpus {
			let text: String
			do {
				let site = Caddy()
				site.domains = ["example.com"]
				site.config.backend = .proxy(.init(upstream: value))

				text = try Caddyfile.build {
					try Caddyfile.site(site, app: app)
				}
			} catch {
				// a rejected value is never emitted, so it cannot inject anything
				continue
			}

			let dir = try Path.mktemp()
			let file = dir / "Caddyfile"
			try text.write(toFile: file.string, atomically: true, encoding: .utf8)

			// reuses the production validator (without su, so no root is needed); it throws when the
			// generated config is invalid
			try await Caddyfile.validate(dir: dir)
			try? dir.delete()
		}
	}
}

@Test func testUnquotedGeneratorIsVulnerable() {
	// a naive generator that interpolates the value produces a new directive line, which is
	// exactly what the backtick-quoted, validated generator prevents
	func naive(_ value: String) -> String {
		"reverse_proxy \(value)"
	}

	let injected = naive("127.0.0.1:9000\nreverse_proxy evil.local")
	#expect(injected.components(separatedBy: "\n").count == 2)

	#expect(throws: (any Error).self) {
		try "127.0.0.1:9000\nreverse_proxy evil.local".quoteCaddy
	}
}
