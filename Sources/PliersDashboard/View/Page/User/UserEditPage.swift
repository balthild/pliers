import Elementary
import Vapor

extension View.Page {
	struct UserEditPage: HTMLPage {
		@View.Context var req: Request

		let model: User

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "User" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			let user = try req.auth.require(User.self)

			h2 { title }
			hr()

			form(
				.method(.post),
				.action("/user/\(try model.uuid)/update"),
				.class("form max-w-200 p-2 border border-gray-400"),
			) {
				label(.class("field")) {
					span { "Username" }
					input(.type(.text), .value(model.username), .disabled)
				}

				div(.class("field")) {
					span { "Privileges" }
					div(.class("flex gap-2")) {
						label(.class("checkbox")) {
							input(
								.type(.checkbox),
								.name("privileges[]"),
								.value(User.Privilege.admin.rawValue),
								.checked.when(model.isAdmin),
								.readonly.when(model.isAdmin && model.id == user.id),
							)
							User.Privilege.admin.rawValue
						}

						for privilege in User.Privilege.allCases where privilege != .admin {
							label(.class("checkbox")) {
								input(
									.type(.checkbox),
									.name("privileges[]"),
									.value(privilege.rawValue),
									.checked.when(model.privileges.contains(privilege)),
								)
								privilege.rawValue
							}
						}
					}
				}

				div(.class("actions")) {
					a(.href("/user"), .class("btn")) { "Cancel" }
					button(.type(.submit), .class("primary")) { "Save" }
				}
			}
		}
	}
}
