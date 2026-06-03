import ConsoleKit
import PliersCommon

extension CommandContext {
	public var config: Config {
		get {
			guard let config = self.userInfo["config"] as? Config else {
				fatalError("Config not set on context")
			}
			return config
		}
		set {
			self.userInfo["config"] = newValue
		}
	}
}
