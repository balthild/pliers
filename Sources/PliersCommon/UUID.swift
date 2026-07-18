import Foundation

extension UUID {
	public var bytes: [UInt8] {
		withUnsafeBytes(of: self.uuid) { Array($0) }
	}
}
