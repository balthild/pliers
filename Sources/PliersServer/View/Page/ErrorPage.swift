import Elementary
import PliersCommon
import Vapor

extension View.Page {
	struct ErrorPage: HTMLDocument {
		let error: Swift.Error

		var title: String { "Error" }

		var head: some HTML {
			View.Component.CommonHead()
		}

		var body: some HTML {
			div(.class("grow bg-gray-100")) {
				main(.class("w-full max-w-lg border border-gray-400 px-4 py-3 mt-24 mx-auto bg-white")) {
					h2(.class("text-base font-bold")) { "Error" }

					switch error {
					case let error as AbortError:
						p(.class("text-sm mt-2")) {
							"\(error.status.code) \(error.reason)"
						}

					case let error as AlertError:
						p(.class("text-sm mt-2")) {
							error.message
						}

						details(.class("text-sm mt-1 mb-3")) {
							summary { "Details" }
							pre(.class("text-xs p-2 mt-0.5 bg-gray-100 overflow-x-auto")) {
								"\(error)"
							}
						}

					default:
						p(.class("text-sm mt-2")) {
							"\(HTTPResponseStatus.internalServerError)"
						}

						#if DEBUG
							details(.class("text-sm mt-1 mb-3")) {
								summary { "Debug" }
								pre(.class("text-xs p-2 mt-0.5 bg-gray-100 overflow-x-auto")) {
									"\(error)"
								}
							}
						#endif
					}

					div(.class("text-sm mt-2")) {
						button(.class("primary"), .on(.click, "history.back()")) { "Back" }
					}
				}
			}
		}
	}
}
