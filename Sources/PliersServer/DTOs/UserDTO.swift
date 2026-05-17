import Fluent
import Vapor

struct UserDTO: Content {
	var id: UInt32

	func toModel() -> User {
		return .init(id: self.id)
	}
}
