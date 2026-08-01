import Foundation
import Path

extension View.Page {
	protocol FileViewMixin {}
}

extension View.Page.FileViewMixin {
	func link(to path: Path, action: String? = nil) -> String {
		var url = URLComponents()

		if let action {
			url.path = "/file/\(action)"
		} else {
			url.path = "/file"
		}

		url.queryItems = [
			.init(name: "path", value: path.string)
		]

		return url.string ?? "/file"
	}
}
