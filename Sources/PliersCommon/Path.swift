import Foundation
import Path

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
