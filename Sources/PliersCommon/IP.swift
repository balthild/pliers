import Foundation
import Glibc

extension String {
	public var isIP: Bool {
		var buffer = [UInt8](repeating: 0, count: 16)

		return self.withCString { pointer in
			inet_pton(AF_INET, pointer, &buffer) == 1
				|| inet_pton(AF_INET6, pointer, &buffer) == 1
		}
	}

	public var isCIDR: Bool {
		if self.isIP {
			return true
		}

		guard let slash = self.lastIndex(of: "/") else {
			return false
		}

		let address = String(self[..<slash])
		let prefix = String(self[self.index(after: slash)...])

		guard address.isIP, let bits = Int(prefix) else {
			return false
		}

		let maximum = address.contains(":") ? 128 : 32
		return (0...maximum).contains(bits)
	}
}
