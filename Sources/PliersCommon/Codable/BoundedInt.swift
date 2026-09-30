public struct BoundedInt<let min: Int, let max: Int>: Codable, Sendable {
	public let rawValue: Int

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let value = try container.decode(Int.self)

		guard (min...max).contains(value) else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "value \(value) is outside the allowed range \(min)...\(max)",
			)
		}

		self.rawValue = value
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.rawValue)
	}
}
