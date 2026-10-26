import PliersCommon
import Vapor

extension Caddyfile {
	private static let dockerNetwork = "172.16.0.0/12"

	static func site(_ site: Caddy, app: Application) throws -> Node {
		let scheme = site.config.tls == nil ? "http://" : "https://"
		let listeners = site.domains.map { "\(scheme)\($0)" }.joined(separator: ", ")

		return try Caddyfile.item(listeners) {
			switch site.config.tls {
			case .acme:
				Caddyfile.empty()
			case .file(let file):
				Caddyfile.item("tls", try file.cert.quoteCaddy, try file.key.quoteCaddy)
			case .none:
				Caddyfile.empty()
			}

			compression(site.config.compression)

			try caching(site.config.cache)

			try cors(site.config.cors)

			try logging(site.config.logging)

			switch site.config.backend {
			case .proxy(let proxy):
				try Caddyfile.item("reverse_proxy", proxy.upstream.quoteCaddy) {
					trustedProxies(site.config.trustedProxies, app: app)
				}

			case .file(let file):
				try Caddyfile.item("file_server") {
					Caddyfile.item("root", try file.root.quoteCaddy)
				}

			case .php(let php):
				try Caddyfile.item("php_fastcgi", php.fpm.quoteCaddy) {
					Caddyfile.item("root", try php.root.quoteCaddy)
				}

			case .none:
				Caddyfile.item("respond", try "It works!".quoteCaddy)
			}

			Caddyfile.item(site.config.custom)
		}
	}

	// MARK: Compression

	private static func compression(_ config: Caddy.Config.Compression) -> Node {
		guard config.enable else {
			return .empty
		}

		guard config.customize else {
			return Caddyfile.item("encode")
		}

		return Caddyfile.item("encode") {
			if config.gzipEnable {
				if let level = config.gzipLevel {
					Caddyfile.item("gzip", String(level.rawValue))
				} else {
					Caddyfile.item("gzip")
				}
			}

			if config.zstdEnable {
				if let level = config.zstdLevel {
					Caddyfile.item("zstd", level.rawValue)
				} else {
					Caddyfile.item("zstd")
				}
			}

			if let minimum = config.minimumLength {
				Caddyfile.item("minimum_length", String(minimum))
			}
		}
	}

	// MARK: Caching

	private static func caching(_ config: Caddy.Config.Cache) throws -> Node {
		guard config.enable else {
			return .empty
		}

		var value = "\(config.visibility.rawValue), max-age=\(config.maxAge ?? 3600)"
		if config.immutable {
			value += ", immutable"
		}

		return Caddyfile.item("header", "Cache-Control", try value.quoteCaddy)
	}

	// MARK: CORS

	private static func cors(_ config: Caddy.Config.CORS) throws -> Node {
		guard config.enable else {
			return .empty
		}

		let origins = config.origins.map(\.trimmed).filter { !$0.isEmpty }

		return try Caddyfile.group {
			if origins.contains("*") {
				try Caddyfile.item("header") {
					Caddyfile.item("Access-Control-Allow-Origin", "*")
					try corsCommon(config)
				}
			} else {
				// Each allowed origin gets its own matcher, and the matching origin is echoed
				// back. A comma-separated list is not valid for `Access-Control-Allow-Origin`.
				for (index, origin) in origins.enumerated() {
					let matcher = "@cors-origin-\(index)"
					Caddyfile.item(matcher, "header", "Origin", try origin.quoteCaddy)
					Caddyfile.item("header", matcher, "Access-Control-Allow-Origin", try origin.quoteCaddy)
				}

				try Caddyfile.item("header") {
					Caddyfile.item("Vary", try "Origin".quoteCaddy)
					try corsCommon(config)
				}
			}

			// answer preflight requests directly so the backend is not involved.
			Caddyfile.item("@cors-preflight", "method", "OPTIONS")
			Caddyfile.item("respond", "@cors-preflight", "204")
		}
	}

	/// Headers that apply regardless of the request origin.
	private static func corsCommon(_ config: Caddy.Config.CORS) throws -> Node {
		return try Caddyfile.group {
			if !config.methods.isEmpty {
				Caddyfile.item(
					"Access-Control-Allow-Methods",
					try config.methods.joined(separator: ", ").quoteCaddy,
				)
			}

			if !config.headers.isEmpty {
				Caddyfile.item(
					"Access-Control-Allow-Headers",
					try config.headers.joined(separator: ", ").quoteCaddy,
				)
			}

			if config.credentials {
				Caddyfile.item("Access-Control-Allow-Credentials", "true")
			}

			if let maxAge = config.maxAge {
				Caddyfile.item("Access-Control-Max-Age", String(maxAge))
			}
		}
	}

	// MARK: Logging

	private static func logging(_ config: Caddy.Config.Logging) throws -> Node {
		guard config.enable else {
			return .empty
		}

		let output = config.output.trimmed

		return try Caddyfile.item("log") {
			if !output.isEmpty {
				Caddyfile.item("output", "file", try output.quoteCaddy)
			}

			Caddyfile.item("format", config.format.rawValue)
		}
	}

	// MARK: Trusted proxies

	private static func trustedProxies(
		_ config: Caddy.Config.TrustedProxies,
		app: Application,
	) -> Node {
		var ranges: [String] = []

		if config.docker {
			ranges.append(dockerNetwork)
		}

		if config.cloudflare {
			ranges.append(contentsOf: app.cloudflareNetworks)
		}

		ranges.append(contentsOf: config.custom)

		let tokens = ["trusted_proxies"] + ranges.map(\.trimmed).filter { !$0.isEmpty }
		guard tokens.count > 1 else {
			return .empty
		}

		return Caddyfile.item(tokens: tokens)
	}
}
