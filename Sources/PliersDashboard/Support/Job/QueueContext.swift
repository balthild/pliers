import AsyncHTTPClient
import Fluent
import NIOFileSystem
import Queues

extension QueueContext {
	public var db: any Database {
		self.application.db
	}

	public var fs: FileSystem {
		.init(threadPool: self.application.threadPool)
	}

	public var http: HTTPClient {
		self.application.http.client.shared
	}
}
