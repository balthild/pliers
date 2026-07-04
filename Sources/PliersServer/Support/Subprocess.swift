import Glibc
import PliersCommon
import Subprocess

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
