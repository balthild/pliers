import Fluent
import Foundation
import PliersCommon
import Vapor

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Caddy: Model, @unchecked Sendable {
	static let schema = "caddy"

	@ID
	var id: UUID?

	@Field(key: "domains")
	var domains: [String]

	@Field(key: "config")
	var config: Config

	init() {}

	struct Config: Codable {
		@Fallback
		var tls: TLS?

		@Fallback
		var backend: Backend?

		@Fallback
		var custom: String

		enum TLS: Codable {
			case acme
			case file(cert: String, key: String)
		}

		enum Backend: Codable {
			case proxy(upstream: String)
			case file(root: String)
			case php(root: String, fcgi: String)
		}
	}
}
