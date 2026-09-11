import CasePaths
import Fluent
import Foundation
import Path
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

	init() {
		self.domains = []
		self.config = .init()
	}

	struct Config: Codable {
		@Fallback
		var tls: TLS?

		@Fallback
		var backend: Backend?

		@Fallback
		var custom: String = ""

		@CasePathable
		enum TLS: Codable, CaseNamable {
			case acme
			case file(File)

			var caseName: String {
				switch self {
				case .acme: return CodingKeys.acme.stringValue
				case .file: return CodingKeys.file.stringValue
				}
			}

			struct File: Codable {
				let cert: String
				let key: String
			}
		}

		@CasePathable
		enum Backend: Codable, CaseNamable {
			case proxy(Proxy)
			case file(File)
			case php(PHP)

			var caseName: String {
				switch self {
				case .proxy: return CodingKeys.proxy.stringValue
				case .file: return CodingKeys.file.stringValue
				case .php: return CodingKeys.php.stringValue
				}
			}

			struct Proxy: Codable {
				let upstream: String
			}

			struct File: Codable {
				let root: String
			}

			struct PHP: Codable {
				let root: String
				let fpm: String
			}
		}
	}
}

extension Caddy {
	var candidateWebRoot: String {
		switch self.config.backend {
		case .file(let file): return file.root
		case .php(let php): return php.root
		default: return self.defaultWebRoot
		}
	}

	var defaultWebRoot: String {
		guard let id = try? self.uuid else { return "" }
		let path = C.www.home / id / "public"
		return path.string
	}

	func assignDefaultWebRoot() throws {
		switch self.config.backend {
		case .file(let file) where file.root.isEmpty:
			self.config.backend = .file(.init(root: self.defaultWebRoot))
		case .php(let php) where php.root.isEmpty:
			self.config.backend = .php(.init(root: self.defaultWebRoot, fpm: php.fpm))
		default:
			break
		}
	}
}
