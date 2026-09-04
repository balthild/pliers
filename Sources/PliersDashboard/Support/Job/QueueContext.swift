import AsyncHTTPClient
import Fluent
import Queues

extension QueueContext {
	public var db: any Database {
		self.application.db
	}

	public var http: HTTPClient {
		.init(
			eventLoopGroup: self.application.eventLoopGroup,
			configuration: .init(),
		)
	}
}
