import Fluent
import Vapor

struct UserDTO: Content {
	var id: UUID?
	var username: String

	static func fromModel(_ model: User) -> Self {
		.init(
			id: model.id,
			username: model.username,
		)
	}
}
