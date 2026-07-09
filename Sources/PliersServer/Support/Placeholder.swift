import Vapor

struct Placeholder {
	let password: String
	let totp: TOTPConfig

	init(app: Application) throws {
		self.password = try app.password.hash("")
		self.totp = TOTPConfig()
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
