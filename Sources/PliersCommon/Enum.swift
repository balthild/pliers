public protocol CaseNamable {
	var `case`: String { get }
}

extension Optional where Wrapped: CaseNamable {
	public var `case`: String? {
		self.map { $0.case }
	}
}
