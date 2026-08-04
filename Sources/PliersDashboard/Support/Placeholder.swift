import Vapor

struct Placeholder {
	let password: User.Password

	init(app: Application) throws {
		self.password = .init()
		self.password.hash = try app.password.hash("")
		self.password.totp = TOTPConfig()
	}

	struct Key: StorageKey {
		typealias Value = Placeholder
	}
}

extension Application {
	var placeholder: Placeholder {
		get { self.storage[Placeholder.Key.self]! }
		set { self.storage[Placeholder.Key.self] = newValue }
	}
}

extension Request {
	var placeholder: Placeholder { self.application.placeholder }
}
