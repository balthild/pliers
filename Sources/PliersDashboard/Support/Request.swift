import Elementary
import Fluent
import NIOConcurrencyHelpers
import Vapor
import VaporElementary
import WebAuthn

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

	var clientAcceptsJson: Bool {
		guard let accept = self.headers.first(name: .accept) else { return false }
		return accept.contains("/json") || accept.contains("+json")
	}
}

extension Request {
	func find<T: Model>(_: T.Type, _ parameter: String) async throws -> T
	where T.IDValue: LosslessStringConvertible {
		guard let id: T.IDValue = self.parameters.get(parameter) else {
			throw Abort(.notFound)
		}

		guard let model = try await T.find(id, on: self.db) else {
			throw Abort(.notFound)
		}

		return model
	}

	func find<T: Model, U: Model>(
		_ relation: ChildrenProperty<T, U>,
		_ parameter: String,
	) async throws -> U
	where U.IDValue: LosslessStringConvertible {
		guard let id: U.IDValue = self.parameters.get(parameter) else {
			throw Abort(.notFound)
		}

		let model = try await relation.query(on: self.db)
			.filter(\._$id == id)
			.first()

		guard let model else {
			throw Abort(.notFound)
		}

		return model
	}
}

extension Request {
	var webAuthn: WebAuthnManager {
		let host = self.url.host ?? "localhost"
		let proto = self.url.scheme ?? "http"
		let origin = self.headers.first(name: .origin) ?? "\(proto)://\(host)"

		return .init(
			configuration: .init(
				relyingPartyID: host,
				relyingPartyName: "Pliers",
				relyingPartyOrigin: origin,
			)
		)
	}
}

extension Request {
	func render(
		status: HTTPStatus = .ok,
		@HTMLBuilder content: () -> sending some HTML,
	) async throws -> Response {
		// false-positive warning produced if no type erasure
		// capture of non-Sendable type '(some HTML).Type' in an isolated closure
		let content = OnceBox<any HTML>(
			content().environment(View.Context.$key, self)
		)

		// not using `VaporElementary::HTMLResponse` because it does not write `.error` on failure
		return Response(
			status: status,
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
