import Elementary
import Vapor

extension UI.Layout {
	struct Auth<Page: HTMLPage>: HTMLLayout {
		typealias Page = Page

		@UI.Context var req: Request

		func title(_ page: borrowing Page) -> String {
			return "\(page.title) - Pliers"
		}

		@HTMLBuilder
		func error(_ error: Swift.Error) -> some HTML {
			UI.Page.Error(error: error)
		}

		@HTMLBuilder
		func head(_ page: borrowing Page) throws -> some HTML {
			UI.Component.CommonHead()
			try page.head()
		}

		@HTMLBuilder
		func body(_ page: borrowing Page) throws -> some HTML {
			let body = try page.body()

			div(.class("grow bg-gray-100")) {
				main(.class("w-full max-w-lg border border-gray-400 p-4 mt-24 mx-auto bg-white")) {
					body
				}
			}
		}
	}
}
