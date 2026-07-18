import Foundation
import Path
import PliersShim

extension Path {
	public static func home(for username: String) -> Self? {
		guard let url = FileManager.default.homeDirectory(forUser: username) else {
			return nil
		}

		return .init(url: url)
	}

	public var canonical: Self? {
		let url = self.url.resolvingSymlinksInPath()
		return .init(url: url)
	}

	public var attrs: Result<[FileAttributeKey: Any], Error> {
		return Result {
			try FileManager.default.attributesOfItem(atPath: self.string)
		}
	}

	public func replace(with other: Path) throws {
		let _ = try FileManager.default.replaceItemAt(self.url, withItemAt: other.url)
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
	public struct AccessMode: OptionSet, Sendable {
		public let rawValue: Int32

		public init(rawValue: Int32) {
			self.rawValue = rawValue
		}

		public static let r = Self(rawValue: R_OK)
		public static let w = Self(rawValue: W_OK)
		public static let x = Self(rawValue: X_OK)

		public static let rw: Self = [.r, .w]
		public static let rx: Self = [.r, .x]
		public static let wx: Self = [.w, .x]
		public static let rwx: Self = [.r, .w, .x]
	}

	public func hasAccess(_ mode: AccessMode, by username: String) -> Bool {
		let result = PliersShim::check_access(mode.rawValue, username, self.string)
		return result == 0
	}
}
