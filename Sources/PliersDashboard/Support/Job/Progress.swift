import Queues
import Vapor

extension Application {
	/// Note: assumes that only one application is running
	var progress: ProgressStorage {
		ProgressStorage.shared
	}
}

extension Request {
	var progress: ProgressStorage {
		self.application.progress
	}
}

extension QueueContext {
	var progress: ProgressStorage {
		self.application.progress
	}
}

actor ProgressStorage {
	fileprivate static let shared = ProgressStorage()

	private var handles: [UUID: ProgressHandle] = [:]

	public func all() -> some Collection {
		return handles.values
	}

	public func get(_ id: UUID) -> ProgressHandle? {
		return handles[id]
	}

	public func create() throws -> ProgressHandle {
		let id = try UUID.roll { self.handles[$0] == nil }

		let progress = ProgressHandle(id)
		handles[id] = progress
		return progress
	}
}

actor ProgressHandle {
	typealias Stream = AsyncStream<ProgressData>
	typealias Mutate = (inout ProgressData) -> Void

	public let id: UUID

	private var counter: Int = 0
	private var receivers: [Int: Stream.Continuation] = [:]

	private var data: ProgressData = .init()

	fileprivate init(_ id: UUID) {
		self.id = id
	}

	func snapshot() -> ProgressData {
		return self.data
	}

	func subscribe() -> Stream {
		let (stream, continuation) = Stream.makeStream()

		let id = self.reserve()
		receivers[id] = continuation
		continuation.onTermination = { [weak self] _ in
			Task { await self?.unsubscribe(id: id) }
		}

		return stream
	}

	func report(mutate: Mutate) {
		mutate(&self.data)

		for continuation in receivers.values {
			continuation.yield(self.data)
		}
	}

	func finish() {
		for continuation in receivers.values {
			continuation.finish()
		}
	}

	private func reserve() -> Int {
		self.counter += 1
		return self.counter
	}

	private func unsubscribe(id: Int) {
		receivers[id] = nil
	}
}

struct ProgressData: Codable {
	var status: Status = .ready
	var progress: Double = 0
	var message: String = ""
	var output: String = ""

	enum Status: String, Codable {
		case ready
		case active
		case done
		case error
	}

	func json() throws -> String {
		let data = try JSONEncoder().encode(self)
		return try String(data: data, encoding: .utf8).expect("invalid utf8 string")
	}

	func sse(_ allocator: ByteBufferAllocator) throws -> ByteBuffer {
		let data = try JSONEncoder().encode(self)

		var buffer = allocator.buffer(capacity: data.count + 8)
		buffer.writeString("data: ")
		buffer.writeBytes(data)
		buffer.writeString("\n\n")

		return buffer
	}
}
