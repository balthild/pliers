import Fluent
import NIOCore
import Path
import PliersCommon
import Testing
import Vapor
import VaporTesting

@testable import PliersDashboard

/// Runs `test` against a fully configured dashboard backed by a throwaway database.
///
/// `configure()` skips the D-Bus and Cloudflare lifecycles under `.testing`, so this needs
/// neither root nor a running D-Bus daemon. The app is not booted yet, so a test may register
/// extra routes before its first `app.testing()` call.
@discardableResult
func withDashboard<T>(_ test: (Application) async throws -> T) async throws -> T {
	let state = try Path.mktemp()
	defer { try? state.delete() }

	let config = try Config(port: 8080, state: state)

	return try await withApp(
		configure: { app in
			let dashboard = PliersDashboard(config: config, app: app)
			try await dashboard.configure()
		},
		test,
	)
}

extension Application {
	/// Writes a server-side session that authenticates `user` and returns its cookie value,
	/// bypassing login so a test can act as an authenticated user.
	func login(_ user: User) async throws -> String {
		let key = UUID().uuidString
		let id = try user.requireID()
		let record = SessionRecord(
			key: .init(string: key),
			data: .init(initialData: ["_UserSession": id.uuidString]),
		)
		try await record.save(on: self.db)
		return key
	}

	/// Authenticates `user` and performs a request as them, mirroring `testing().test(...)`.
	///
	/// The live transport is needed to exercise anything behind `TrustedProxiesMiddleware`, since
	/// the in-memory tester leaves `remoteAddress` nil.
	@discardableResult
	func test(
		_ method: HTTPMethod,
		_ path: String,
		as user: User,
		headers extra: HTTPHeaders = [:],
		scheme: String? = nil,
		using transport: Application.Method = .inMemory,
		body: ByteBuffer? = nil,
		afterResponse: (TestingHTTPResponse) async throws -> Void,
	) async throws -> TestingApplicationTester {
		let key = try await self.login(user)

		var headers: HTTPHeaders = ["Cookie": "pliers_session=\(key)"]
		for (name, value) in extra {
			headers.replaceOrAdd(name: name, value: value)
		}
		if let scheme {
			headers.replaceOrAdd(name: "X-Forwarded-Proto", value: scheme)
		}

		return try await self.testing(method: transport).test(
			method,
			path,
			headers: headers,
			body: body,
			afterResponse: afterResponse,
		)
	}
}
