import ConsoleKit
import PliersCommon

private let key = ObjectIdentifier(Config.self)

extension CommandContext {
	public var config: Config {
		get { self.userInfo[key] as! Config }
		set { self.userInfo[key] = newValue }
	}
}
