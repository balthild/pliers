import Elementary
import Vapor

extension View.Page {
	struct UserListPage: HTMLPage {
		let users: [User]

		let layout = View.Layout.DashboardLayout<Self>()

		var title: String { "User" }

		@HTMLBuilder
		func body() throws -> sending some HTML {
			h2 { title }
			hr()

			table {
				thead {
					tr {
						th { "Name" }
						th { "Privileges" }
						th {}
					}
				}

				tbody {
					for user in users {
						tr {
							td { user.username }
							td {
								if user.isAdmin {
									span(.class("mr-1")) { "admin" }
								} else {
									for privilege in user.privileges {
										span(.class("mr-1")) { privilege.rawValue }
									}
								}
							}
							td {
								div(.class("flex gap-2")) {
									a(.href("/user/\(try user.uuid)")) { "Edit" }
								}
							}
						}
					}

					if users.isEmpty {
						tr {
							td(.colspan(3), .class("text-center text-gray-500")) {
								"No data."
							}
						}
					}
				}
			}
		}
	}
}
