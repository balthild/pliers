import PliersCommon
import Testing

@Test func testOriginRejectsWhenNeitherPresent() {
	#expect(Origin.isSameOrigin(origin: nil, referer: nil, host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "", referer: "   ", host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "null", referer: nil, host: "panel.example.com", scheme: "https") == false)
}

@Test func testOriginAcceptsMatching() {
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com", referer: nil, host: "panel.example.com", scheme: "https"))
	#expect(Origin.isSameOrigin(origin: "http://127.0.0.1:8080", referer: nil, host: "127.0.0.1:8080", scheme: "http"))
}

@Test func testOriginNormalizesDefaultPort() {
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com:443", referer: nil, host: "panel.example.com", scheme: "https"))
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com", referer: nil, host: "panel.example.com:443", scheme: "https"))
}

@Test func testOriginRejectsMismatch() {
	#expect(Origin.isSameOrigin(origin: "https://evil.example.com", referer: nil, host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "http://panel.example.com", referer: nil, host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com:8443", referer: nil, host: "panel.example.com", scheme: "https") == false)
}

@Test func testOriginFallsBackToReferer() {
	#expect(Origin.isSameOrigin(origin: nil, referer: "https://panel.example.com/cron/1/edit", host: "panel.example.com", scheme: "https"))
	#expect(Origin.isSameOrigin(origin: "null", referer: "https://panel.example.com/", host: "panel.example.com", scheme: "https"))
	#expect(Origin.isSameOrigin(origin: nil, referer: "https://evil.example.com/", host: "panel.example.com", scheme: "https") == false)
}

@Test func testOriginTakesPrecedenceOverReferer() {
	#expect(Origin.isSameOrigin(origin: "https://evil.example.com", referer: "https://panel.example.com/", host: "panel.example.com", scheme: "https") == false)
}

@Test func testOriginAllowlist() {
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com", referer: nil, host: "localhost:8080", scheme: "https", allowlist: ["https://panel.example.com"]))
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com", referer: nil, host: "localhost:8080", scheme: "https", allowlist: []) == false)
	#expect(Origin.isSameOrigin(origin: "https://evil.example.com", referer: nil, host: "localhost:8080", scheme: "https", allowlist: ["https://panel.example.com"]) == false)
}

@Test func testOriginRejectsMalformed() {
	#expect(Origin.isSameOrigin(origin: "not a url", referer: nil, host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com evil", referer: nil, host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "ftp://panel.example.com", referer: nil, host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "https://user:pass@panel.example.com", referer: nil, host: "panel.example.com", scheme: "https") == false)
	#expect(Origin.isSameOrigin(origin: "https://panel.example.com", referer: nil, host: "", scheme: "https") == false)
}
