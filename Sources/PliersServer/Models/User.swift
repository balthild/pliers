import Fluent

import struct Foundation.UUID

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class User: Model, @unchecked Sendable {
	static let schema = "user"

	@ID(custom: "id")
	var id: UInt32?

	@Field(key: "title")
	var title: String

	init() {}

	init(id: UInt32) {
		self.id = id
	}

	func toDTO() -> UserDTO {
		.init(
			id: self.id!,
		)
	}
}
