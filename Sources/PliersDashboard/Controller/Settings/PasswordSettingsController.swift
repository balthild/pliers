import Fluent
import PliersCommon
import Vapor
import VaporElementary

struct PasswordSettingsController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped("settings", "password")
			.grouped(User.requireLoggedIn())

		group.post(use: self.create)
		group.post("update", use: self.update)
		group.post("delete", use: self.delete)
	}

	@Sendable
	func create(req: Request) async throws -> Response {
		struct Input: Content {
			let password: String
			let password_confirmation: String
			let totp_config: TOTPConfig
			let totp_code: String
		}

		let input = try req.content.decode(Input.self)

		guard input.password == input.password_confirmation else {
			throw AlertError("passwords do not match")
		}

		guard input.totp_config.verify(input.totp_code) else {
			throw AlertError("invalid TOTP code")
		}

		let user = try req.auth.require(User.self)

		user.password = User.Password()
		user.password!.hash = try await req.password.async.hash(input.password)
		user.password!.totp = input.totp_config
		try await user.save(on: req.db)

		return req.redirect(.back)
	}

	@Sendable
	func update(req: Request) async throws -> Response {
		struct Input: Content {
			let password: String
			let password_confirmation: String
		}

		let input = try req.content.decode(Input.self)

		guard input.password == input.password_confirmation else {
			throw AlertError("passwords do not match")
		}

		let user = try req.auth.require(User.self)
		guard let password = user.password else {
			throw AlertError("password auth is not enabled")
		}

		password.hash = try await req.password.async.hash(input.password)
		try await user.save(on: req.db)

		return req.redirect(.back)
	}

	@Sendable
	func delete(req: Request) async throws -> Response {
		let user = try req.auth.require(User.self)

		user.password = nil
		try await user.save(on: req.db)

		return req.redirect(.back)
	}
}
