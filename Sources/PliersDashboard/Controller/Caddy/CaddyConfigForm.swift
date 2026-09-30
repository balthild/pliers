import PliersCommon
import Vapor

/// Form-input counterpart of `Caddy.Config`.
///
/// The model stores list-valued settings as real JSON arrays, but the site form submits
/// them as newline-separated textareas. This layer applies `@Lines` to split such inputs
/// while decoding the form body, then converts to the model representation via `config`.
///
/// TODO: remove this after implementing an array-input component in the future.
extension Caddy.Config {
	struct Form: Codable {
		@Fallback
		var tls: TLS?

		@Fallback
		var backend: Backend?

		@Fallback
		var compression: Compression

		@Fallback
		var cache: Cache

		@Fallback
		var cors: CORS.Form

		@Fallback
		var logging: Logging

		@Fallback
		var trustedProxies: TrustedProxies.Form

		@Fallback
		var custom: String = ""

		var config: Caddy.Config {
			var config = Caddy.Config()
			config.tls = self.tls
			config.backend = self.backend
			config.compression = self.compression
			config.cache = self.cache
			config.cors = self.cors.config
			config.logging = self.logging
			config.trustedProxies = self.trustedProxies.config
			config.custom = self.custom
			return config
		}
	}
}

extension Caddy.Config.CORS {
	struct Form: Codable, Default {
		let enable: Bool

		@Lines
		var origins: [String]

		@Lines
		var methods: [String]

		@Lines
		var headers: [String]

		let credentials: Bool

		@AllowEmpty
		var maxAge: UInt?

		var config: Caddy.Config.CORS {
			.init(
				enable: self.enable,
				origins: self.origins,
				methods: self.methods,
				headers: self.headers,
				credentials: self.credentials,
				maxAge: .init(wrappedValue: self.maxAge),
			)
		}

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
}

extension Caddy.Config.TrustedProxies {
	struct Form: Codable, Default {
		let docker: Bool
		let cloudflare: Bool

		@Lines
		var custom: [String]

		var config: Caddy.Config.TrustedProxies {
			.init(
				docker: self.docker,
				cloudflare: self.cloudflare,
				custom: self.custom,
			)
		}

		static var defaultValue: Self {
			.init(docker: false, cloudflare: false, custom: [])
		}
	}
}
