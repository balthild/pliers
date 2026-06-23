import PliersCommon
import Vapor

extension Config {
	struct Key: StorageKey {
		typealias Value = Config
	}
}

extension Application {
	var config: Config? {
		get { self.storage[Config.Key.self] }
		set { self.storage[Config.Key.self] = newValue }
	}
}

extension Request {
	var config: Config { self.application.config! }
}
