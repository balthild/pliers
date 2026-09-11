import CasePaths
import Fluent
import Foundation
import PliersCommon
import RegexBuilder
import Vapor

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class PHP: Model, @unchecked Sendable {
	static let schema = "php"

	@ID
	var id: UUID?

	@Field(key: "version")
	var version: Version

	@Field(key: "config")
	var config: Config

	init() {
		self.config = .init()
	}

	struct Version: Sendable {
		static var pattern: Regex<(Substring, Int, Int, Int)> {
			Regex {
				TryCapture(OneOrMore(.digit)) { Int($0) }
				"."
				TryCapture(OneOrMore(.digit)) { Int($0) }
				"."
				TryCapture(OneOrMore(.digit)) { Int($0) }
			}
		}

		let major: Int
		let minor: Int
		let patch: Int

		var string: String {
			"\(major).\(minor).\(patch)"
		}

		init(major: Int, minor: Int, patch: Int) {
			self.major = major
			self.minor = minor
			self.patch = patch
		}

		init(parse string: Substring) throws {
			let matched = try Self.pattern.wholeMatch(in: string)
				.expect("invalid version \(string)")

			self.init(major: matched.1, minor: matched.2, patch: matched.3)
		}

		init(parse string: String) throws {
			try self.init(parse: string[...])
		}
	}

	struct Config: Codable {
		@Fallback
		var listen: Listen = .unix

		@Fallback
		var pm: PM = .dynamic

		@Fallback
		var maxChildren: Int = 5

		@Fallback
		var startServers: Int = 2

		@Fallback
		var minSpareServers: Int = 1

		@Fallback
		var maxSpareServers: Int = 3

		@Fallback
		var maxRequests: Int = 500

		@Fallback
		var terminateTimeout: Int = 0

		@Fallback
		var memoryLimit: String = "128M"

		@Fallback
		var uploadMaxFilesize: String = "2M"

		@Fallback
		var postMaxSize: String = "8M"

		@Fallback
		var maxExecutionTime: Int = 30

		@CasePathable
		enum Listen: Codable, Default, CaseNamable {
			case unix
			case tcp(String)

			static var defaultValue: Self { .unix }

			var `case`: String {
				switch self {
				case .unix: return CodingKeys.unix.stringValue
				case .tcp: return CodingKeys.tcp.stringValue
				}
			}
		}

		enum PM: String, Codable, Default {
			case `dynamic`
			case `static`
			case `ondemand`

			static var defaultValue: Self { .dynamic }
		}
	}
}

extension PHP {
	var configurator: PHPConfigurator {
		PHPConfigurator(version: self.version)
	}
}

extension PHP.Version: Equatable {}

extension PHP.Version: Hashable {}

extension PHP.Version: Codable {
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		try self.init(parse: string)
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(string)
	}
}

extension PHP.Version: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		(lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
	}
}

extension PHP.Version: CustomStringConvertible {
	var description: String {
		string
	}
}

extension PHP.Version: LosslessStringConvertible {
	init?(_ description: String) {
		try? self.init(parse: description)
	}
}
