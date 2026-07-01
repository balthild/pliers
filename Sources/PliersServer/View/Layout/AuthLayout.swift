import Elementary
import Vapor

extension View.Layout {
	struct AuthLayout<Page: HTMLPage>: HTMLLayout {
		typealias Page = Page

		@View.Context var req: Request

		func title(_ page: borrowing Page) -> String {
			return "\(page.title) - Pliers"
		}

		@HTMLBuilder
		func error(_ error: Swift.Error) -> some HTML {
			View.Page.ErrorPage(error: error)
		}

		@HTMLBuilder
		func head(_ page: borrowing Page) throws -> some HTML {
			View.Component.CommonHead()
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
