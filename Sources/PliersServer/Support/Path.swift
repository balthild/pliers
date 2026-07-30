import Path

extension Path {
	struct ArchiveType: Sendable {
		private enum exts {
			static let zip = [".zip"]
			static let tar = [
				".tar",
				".tgz",
				".tbz2",
				".txz",
				".tzst",
				".tar.gz",
				".tar.bz2",
				".tar.xz",
				".tar.zst",
			]
		}

		fileprivate let rawValue: [String]

		fileprivate init(rawValue: [String]) {
			self.rawValue = rawValue
		}

		public static let any = Self(rawValue: exts.zip + exts.tar)
		public static let zip = Self(rawValue: exts.zip)
		public static let tar = Self(rawValue: exts.tar)
	}

	func isArchive(of type: ArchiveType = .any) -> Bool {
		let str = self.string

		for ext in type.rawValue {
			if str.hasSuffix(ext) {
				return true
			}
		}

		return false
	}
}
