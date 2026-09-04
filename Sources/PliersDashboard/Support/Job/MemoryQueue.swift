import DequeModule
import NIOConcurrencyHelpers
import Queues
import Vapor

extension Application.Queues.Provider {
	public static var memory: Self {
		.init { $0.queues.use(custom: MemoryQueuesDriver()) }
	}
}

public struct MemoryQueuesDriver: QueuesDriver {
	private let queues: NIOLockedValueBox<[String: MemoryQueueActor]> = .init([:])

	public func makeQueue(with context: QueueContext) -> Queue {
		let inner = self.queues.withLockedValue({ queues in
			let key = context.queueName.string
			if let existing = queues[key] {
				return existing
			}

			let creating = MemoryQueueActor(context: context)
			queues[key] = creating
			return creating
		})

		let context = QueueContext(
			queueName: context.queueName,
			configuration: context.configuration,
			application: context.application,
			logger: context.logger,
			on: inner.eventLoop,
		)

		return MemoryQueue(context: context, inner: inner)
	}

	public func shutdown() {}
}

private struct MemoryQueue: Queue {
	let context: QueueContext
	let inner: MemoryQueueActor

	init(context: QueueContext, inner: MemoryQueueActor) {
		precondition(context.eventLoop === inner.eventLoop)
		self.context = context
		self.inner = inner
	}

	func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
		self.context.eventLoop.makeFutureWithTask({
			try await self.inner.get(id.string)
		})
	}

	func set(_ id: JobIdentifier, to storage: JobData) -> EventLoopFuture<Void> {
		self.context.eventLoop.makeFutureWithTask {
			try await self.inner.set(id.string, to: storage)
		}
	}

	func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
		self.context.eventLoop.makeFutureWithTask {
			try await self.inner.remove(id.string)
		}
	}

	func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
		self.context.eventLoop.makeFutureWithTask {
			try await self.inner.push(id.string)
		}
	}

	func pop() -> EventLoopFuture<JobIdentifier?> {
		self.context.eventLoop.makeFutureWithTask {
			try await self.inner.pop().map(JobIdentifier.init)
		}
	}
}

private actor MemoryQueueActor {
	var jobs: [String: JobData] = [:]
	var queue: Deque<String> = []
	var active: Set<String> = []

	nonisolated let eventLoop: any EventLoop

	nonisolated var unownedExecutor: UnownedSerialExecutor {
		self.eventLoop.executor.asUnownedSerialExecutor()
	}

	init(context: QueueContext) {
		self.eventLoop = context.eventLoop
	}

	func get(_ id: String) throws -> JobData {
		try self.jobs[id].expect("job \(id) not found")
	}

	func set(_ id: String, to storage: JobData) throws {
		self.jobs[id] = storage
	}

	func remove(_ id: String) throws {
		self.jobs[id] = nil
		self.active.remove(id)
	}

	func push(_ id: String) throws {
		self.queue.append(id)
		self.active.remove(id)
	}

	func pop() throws -> String? {
		guard let id = self.queue.popFirst() else {
			return nil
		}

		self.active.insert(id)
		return id
	}
}
