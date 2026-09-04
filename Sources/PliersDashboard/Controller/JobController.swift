import Fluent
import Vapor

struct JobController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes.grouped(User.requireLoggedIn()).group("job", ":id") { group in
			group.get("progress", use: progress)
		}
	}

	@Sendable
	func progress(req: Request) async throws -> Response {
		guard let id: UUID = req.parameters.get("id") else {
			throw Abort(.notFound)
		}

		guard let progress = await req.progress.get(id) else {
			throw Abort(.notFound)
		}

		return Response(
			status: .ok,
			headers: [
				"Content-Type": "text/event-stream",
				"Cache-Control": "no-cache",
				"Connection": "keep-alive",
				"X-Accel-Buffering": "no",
			],
			body: .init(managedAsyncStream: { writer in
				for await data in await progress.subscribe() {
					let buffer = try data.sse(req.byteBufferAllocator)
					try await writer.writeBuffer(buffer)
				}
			}),
		)
	}
}
