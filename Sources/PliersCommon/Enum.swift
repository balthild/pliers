public protocol VariantNamable {
	var variant: String { get }
}

extension Optional where Wrapped: VariantNamable {
	public var variant: String {
		switch self {
		case .some(let value):
			return value.variant
		case .none:
			return ""
		}
	}
}
