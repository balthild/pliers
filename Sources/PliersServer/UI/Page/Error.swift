import Elementary
import PliersCommon

extension UI.Page {
	struct Error: HTMLDocument {
		let error: Swift.Error

		var title: String { "Error" }

		var head: some HTML {
			UI.Component.CommonHead()
		}

		var body: some HTML {
			div(.class("grow bg-gray-100")) {
				main(.class("w-full max-w-lg border border-gray-400 px-4 py-3 mt-24 mx-auto bg-white")) {
					h2(.class("text-base font-bold")) { "Error" }

					if let alert = error as? AlertError {
						p(.class("text-sm mt-2")) { alert.message }

						details(.class("text-sm mt-1 mb-3")) {
							summary { "Details" }
							pre(.class("text-xs p-2 mt-0.5 bg-gray-100 overflow-x-auto")) {
								"\(alert)"
							}
						}
					} else {
						p(.class("text-sm mt-2")) { "Internal error occurred" }
					}

					div(.class("text-sm mt-2")) {
						button(.class("primary"), .on(.click, "history.back()")) { "Back" }
					}
				}
			}
		}
	}
}
