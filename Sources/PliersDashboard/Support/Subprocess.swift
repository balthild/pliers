import Glibc
import Path
import PliersCommon
import Subprocess
import SystemPackage

extension Executable {
	@inline(always)
	public static func path(_ path: Path) -> Self {
		return .path(.init(path.string))
	}
}

extension PlatformOptions {
	public static func su(_ username: String) throws -> Self {
		if username == "root" {
			return .init()
		}

		guard let passwd = getpwnam(username) else {
			throw RuntimeError("invalid user")
		}

		var options = Self()
		options.userID = passwd.pointee.pw_uid
		options.groupID = passwd.pointee.pw_gid
		options.supplementaryGroups = []

		return options
	}
}

extension Execution where Error == SequenceOutput {
	public static func stderrLastLine(execution: Self) async throws -> String {
		try await execution.standardError.strings().reduce("") { last, line in
			line.isEmpty ? last : line
		}
	}
}
