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
		var compression: Compression

		@Fallback
		var cache: Cache

		@Fallback
		var cors: CORS

		@Fallback
		var logging: Logging

		@Fallback
		var trustedProxies: TrustedProxies

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

		struct Compression: Codable, Default {
			let enable: Bool
			let customize: Bool
			let gzipEnable: Bool
			@AllowEmpty var gzipLevel: BoundedInt<1, 9>?
			let zstdEnable: Bool
			@AllowEmpty var zstdLevel: ZstdLevel?
			@AllowEmpty var minimumLength: UInt?

			enum ZstdLevel: String, Codable, CaseIterable {
				case `default`
				case fastest
				case better
				case best
			}

			static var defaultValue: Self {
				.init(
					enable: true,
					customize: false,
					gzipEnable: false,
					gzipLevel: nil,
					zstdEnable: false,
					zstdLevel: nil,
					minimumLength: nil,
				)
			}
		}

		struct Cache: Codable, Default {
			let enable: Bool
			@AllowEmpty var maxAge: UInt?
			let visibility: Visibility
			let immutable: Bool

			enum Visibility: String, Codable, CaseIterable {
				case `public`
				case `private`
			}

			static var defaultValue: Self {
				.init(
					enable: false,
					maxAge: nil,
					visibility: .public,
					immutable: false,
				)
			}
		}

		struct CORS: Codable, Default {
			var enable: Bool
			@TrimCompact var origins: [String]
			@TrimCompact var methods: [String]
			@TrimCompact var headers: [String]
			var credentials: Bool
			@AllowEmpty var maxAge: UInt?

			static var defaultValue: Self {
				.init(
					enable: false,
					origins: [],
					methods: [],
					headers: [],
					credentials: false,
					maxAge: nil,
				)
			}
		}

		struct Logging: Codable, Default {
			var enable: Bool
			var output: String
			var format: Format

			enum Format: String, Codable, CaseIterable {
				case console
				case json
			}

			static var defaultValue: Self {
				.init(enable: false, output: "", format: .console)
			}
		}

		struct TrustedProxies: Codable, Default {
			var docker: Bool
			var cloudflare: Bool
			@TrimCompact var custom: [String]

			static var defaultValue: Self {
				.init(docker: false, cloudflare: false, custom: [])
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

	var defaultLogPath: String {
		guard let id = try? self.uuid else { return "" }
		let path = C.caddy.log / "\(id).log"
		return path.string
	}

	func assignDefaultLogPath() throws {
		guard self.config.logging.enable else { return }
		guard self.config.logging.output.trimmed.isEmpty else { return }

		self.config.logging = .init(
			enable: true,
			output: self.defaultLogPath,
			format: self.config.logging.format,
		)
	}
}
