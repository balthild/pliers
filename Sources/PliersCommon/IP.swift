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

	/// Whether this IP literal lies inside the given IP or CIDR range.
	///
	/// A bare address (no `/`) matches only itself. Addresses of different families never match,
	/// and a malformed range returns `false`, so a typo can only ever narrow the trusted set.
	public func isInCIDR(_ range: String) -> Bool {
		let parts = range.trimmed.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)

		guard let network = Self.ipBytes(String(parts[0])), let address = Self.ipBytes(self) else {
			return false
		}
		guard network.count == address.count else {
			return false
		}

		let prefix: Int
		if parts.count == 2 {
			guard let bits = Int(parts[1]), (0...(network.count * 8)).contains(bits) else {
				return false
			}
			prefix = bits
		} else {
			prefix = network.count * 8
		}

		let wholeBytes = prefix / 8
		if wholeBytes > 0 && !address[0..<wholeBytes].elementsEqual(network[0..<wholeBytes]) {
			return false
		}

		let remaining = prefix % 8
		guard remaining > 0 else {
			return true
		}

		let mask = UInt8(truncatingIfNeeded: 0xff << (8 - remaining))
		return (address[wholeBytes] & mask) == (network[wholeBytes] & mask)
	}

	/// Decodes an IPv4 or IPv6 literal into its network-order bytes, or `nil` if it is neither.
	private static func ipBytes(_ string: String) -> [UInt8]? {
		var buffer = [UInt8](repeating: 0, count: 16)

		let length = string.withCString { pointer -> Int in
			if inet_pton(AF_INET, pointer, &buffer) == 1 {
				return 4
			}

			return inet_pton(AF_INET6, pointer, &buffer) == 1 ? 16 : 0
		}

		guard length > 0 else {
			return nil
		}

		return Array(buffer[0..<length])
	}
}
