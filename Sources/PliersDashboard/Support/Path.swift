import Path

extension Path {
	struct ArchiveType: Sendable {
		fileprivate let exts: [String]
		fileprivate init(_ exts: [String]) {
			self.exts = exts
		}

		public static let any = Self(zip.exts + tar.exts)
		public static let zip = Self([".zip"])
		public static let tar = Self(
			[".tar"] + ["gz", "bz2", "xz", "zst"].flatMap({ [".tar.\($0)", ".t\($0)"] })
		)
	}

	func isArchive(of type: ArchiveType = .any) -> Bool {
		for ext in type.exts {
			if self.string.hasSuffix(ext) {
				return true
			}
		}

		return false
	}
}
