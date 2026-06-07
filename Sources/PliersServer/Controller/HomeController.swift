import Fluent
import Vapor

struct HomeController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		routes.get(use: self.index)
		routes.get("hello", use: self.hello)
	}

	@Sendable
	func index(req: Request) async throws -> Response {
		return req.redirect(to: "/dashboard")
	}

	@Sendable
	func hello(req: Request) async throws -> String {
		return "Hello, world!"
	}
}
