import Fluent

extension Model where IDValue == UUID {
	public var uuid: String {
		get throws {
			let id = try self.requireID()
			return id.string
		}
	}
}
