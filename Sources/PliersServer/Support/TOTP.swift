import Foundation
import PliersCommon
import Vapor

/// This cannot be an extension of `TOTP` because the fields are internal
struct TOTPConfig {
	let key: SymmetricKey
	let digest: OTPDigest
	let digits: OTPDigits
	let interval: Int

	public init() {
		self.key = SymmetricKey(size: .init(bitCount: 160))
		self.digest = .sha256
		self.digits = .eight
		self.interval = 30
	}

	public init(url: String) throws {
		let url = try URLComponents(string: url).expect("invalid totp url")

		var params = [String: String]()
		for item in url.queryItems ?? [] {
			params[item.name] = item.value
		}

		let secret = try params["secret"].expect("missing secret in totp url")
		let data = try Data(base32Encoded: secret).expect("invalid secret in totp url")
		self.key = SymmetricKey(data: data)

		self.digest = try .init(params["algorithm"] ?? "SHA1").expect("invalid algorithm in totp url")
		self.digits = try .init(params["digits"] ?? "6").expect("invalid digits in totp url")
		self.interval = try Int(params["period"] ?? "30").expect("invalid period in totp url")
	}

	public func toURL() -> String {
		let secret = self.key
			.withUnsafeBytes { $0.base32String() }
			.trimmingSuffix { $0 == "=" }

		var url = URLComponents()
		url.scheme = "otpauth"
		url.host = "totp"
		url.path = "/pliers"
		url.queryItems = [
			.init(name: "secret", value: String(secret)),
			.init(name: "issuer", value: "Pliers"),
			.init(name: "algorithm", value: self.digest.string),
			.init(name: "digits", value: self.digits.string),
			.init(name: "period", value: "\(self.interval)"),
		]

		return url.string!
	}

	public func verify(_ code: String) -> Bool {
		let reference = TOTP.generate(
			key: self.key,
			digest: self.digest,
			digits: self.digits,
			interval: self.interval,
			time: .now,
		)

		return reference == code
	}
}

extension TOTPConfig: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)
		try self.init(url: value)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.toURL())
	}
}

extension OTPDigest {
	public init?(_ string: String) {
		switch string {
		case "SHA1": self = .sha1
		case "SHA256": self = .sha256
		case "SHA512": self = .sha512
		default: return nil
		}
	}

	public var string: String {
		switch self {
		case .sha1: return "SHA1"
		case .sha256: return "SHA256"
		case .sha512: return "SHA512"
		}
	}
}

extension OTPDigits {
	public init?(_ string: String) {
		switch string {
		case "6": self = .six
		case "7": self = .seven
		case "8": self = .eight
		default: return nil
		}
	}

	public var string: String {
		switch self {
		case .six: return "6"
		case .seven: return "7"
		case .eight: return "8"
		}
	}
}
