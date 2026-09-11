import Foundation

extension UUID {
	public var bytes: [UInt8] {
		withUnsafeBytes(of: self.uuid) { Array($0) }
	}

	public var string: String {
		self.uuidString.lowercased()
	}
}

extension UUID {
	public static func roll(retries: Int = 3, unique: (UUID) -> Bool) throws -> UUID {
		for _ in 0..<retries {
			let uuid = UUID()
			if unique(uuid) {
				return uuid
			}
		}

		throw RuntimeError("failed to create a unique uuid after \(retries) retries")
	}
}
