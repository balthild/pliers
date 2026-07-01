import Elementary
import Vapor

extension View {
	@propertyWrapper
	struct Context: Sendable {
		@TaskLocal static var key: Request?

		let env = Elementary::Environment(requiring: Self.$key)

		public var wrappedValue: Request {
			env.wrappedValue
		}
	}
}
