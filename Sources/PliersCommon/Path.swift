import Foundation
import Path
import Subprocess

extension Path {
	public static func home(for username: String) -> Self? {
		guard let url = FileManager.default.homeDirectory(forUser: username) else {
			return nil
		}

		return Self(url: url)
	}

	public var canonical: Self? {
		let url = self.url.resolvingSymlinksInPath()
		return Self(url: url)
	}

	public var attrs: Result<[FileAttributeKey: Any], Error> {
		return Result {
			try FileManager.default.attributesOfItem(atPath: self.string)
		}
	}

	public func hasPrefix(_ prefix: Path) -> Bool {
		let longer = self.components
		let shorter = prefix.components
		guard longer.count >= shorter.count else {
			return false
		}

		for (index, component) in shorter.enumerated() {
			if longer[index] != component {
				return false
			}
		}

		return true
	}
}

extension Path {
	public struct Access: OptionSet, Sendable {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		public static let r = Self(rawValue: 1 << 0)
		public static let w = Self(rawValue: 1 << 1)
		public static let x = Self(rawValue: 1 << 2)

		public static let rw: Self = [.r, .w]
		public static let rx: Self = [.r, .x]
		public static let rwx: Self = [.r, .w, .x]

		fileprivate var flags: [String] {
			var result: [String] = []
			if self.contains(.r) { result.append("-r") }
			if self.contains(.w) { result.append("-w") }
			if self.contains(.x) { result.append("-x") }
			return result
		}
	}

	public func hasAccess(_ access: Access, by username: String) async throws -> Bool {
		if username == "root" {
			return true
		}

		guard let passwd = getpwnam(username) else {
			return false
		}

		var options = Subprocess.PlatformOptions()
		options.userID = passwd.pointee.pw_uid
		options.groupID = passwd.pointee.pw_gid

		let cmd = "test"
		let args = access.flags.map { [$0, self.string] }.joined(separator: ["-a"])

		let result = try await Subprocess.run(
			.name(cmd),
			arguments: .init(Array(args)),
			environment: .custom([]),
			platformOptions: options,
			output: .discarded,
		)

		return result.terminationStatus == .exited(0)
	}
}
