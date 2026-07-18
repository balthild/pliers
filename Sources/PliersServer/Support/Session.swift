import Vapor

extension SessionData {
	mutating func remove(_ key: String) -> String? {
		defer { self[key] = nil }
		return self[key]
	}
}
