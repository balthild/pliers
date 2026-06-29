import Elementary
import NIOConcurrencyHelpers
import Vapor
import VaporElementary

extension Request {
	enum SpecialRedirect {
		case back
	}

	func redirect(_ location: SpecialRedirect) -> Response {
		switch location {
		case .back:
			let referrer = self.headers.first(name: .referer) ?? "/"
			return self.redirect(to: referrer)
		}
	}
}

extension Request {
	func render(@HTMLBuilder content: () -> sending some HTML) async throws -> Response {
		// false-positive warning produced if no type erasure
		// capture of non-Sendable type '(some HTML).Type' in an isolated closure
		let content = OnceBox<any HTML>(
			content().environment(UI.Context.$key, self)
		)

		// not using `VaporElementary::HTMLResponse` because it does not write `.error` on failure
		return Response(
			status: .ok,
			headers: ["Content-Type": "text/html; charset=utf-8"],
			body: .init(asyncStream: { writer in
				// vapor bug: this callback is invoked multiple times unexpectedly
				// https://github.com/vapor/vapor/issues/3002
				guard let content = content.take() else { return }

				do {
					try await writer.writeHTML(content)
					try await writer.write(.end)
				} catch {
					self.logger.report(error: error)
					try await writer.write(.error(error))
				}
			}),
		)
	}
}
