import Foundation

extension String {
	public var quoteJSON: String {
		let encoded = try! JSONEncoder().encode(self)
		return .init(data: encoded, encoding: .utf8)!
	}
}
