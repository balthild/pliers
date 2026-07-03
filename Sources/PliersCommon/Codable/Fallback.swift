@propertyWrapper
public struct Fallback<T>: Codable
where T: Codable & Default {
	public var wrappedValue: T

	public init() {
		self.wrappedValue = T.defaultValue
	}

	public init(wrappedValue: T) {
		self.wrappedValue = wrappedValue
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		// `Optional` needs special handling or it will be always `nil`
		// Swift's `Codable` is so fucking annoying unlike Rust's `serde`
		if let type = T.self as? any CodableOptional.Type {
			if let value = try? container.decode(type.wrappedType) {
				self.wrappedValue = value as? T ?? T.defaultValue
			} else {
				self.wrappedValue = T.defaultValue
			}
		} else {
			if let value = try? container.decode(T.self) {
				self.wrappedValue = value
			} else {
				self.wrappedValue = T.defaultValue
			}
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue)
	}
}

extension Fallback: Sendable
where T: Sendable {}

extension KeyedDecodingContainer {
	func decode<T>(_ type: Fallback<T>.Type, forKey key: Key) throws -> Fallback<T>
	where T: Codable & Default {
		return try decodeIfPresent(type, forKey: key) ?? Fallback()
	}
}

private protocol CodableOptional {
	associatedtype Wrapped: Codable
	static var wrappedType: Wrapped.Type { get }
}

extension Optional: CodableOptional
where Wrapped: Codable {
	static var wrappedType: Wrapped.Type { Wrapped.self }
}
