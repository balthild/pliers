import Elementary
import PliersCommon
import Vapor

extension UI.Component {
	struct ErrorBoundary<Content: HTML>: HTML {
		@UI.Context var req: Request

		let result: Result<Content, ChainError>

		init(
			file: String = #file,
			line: Int = #line,
			function: String = #function,
			@HTMLBuilder content: @escaping () throws -> Content,
		) {
			self.result = Result { try content() }
				.context("rendering html", file: file, line: line, function: function)
		}

		var body: some HTML {
			switch result {
			case .success(let content):
				content
			case .failure(let error):
				let _ = req.logger.report(error: error)

				span(.style("color: red;")) {
					"An error occurred while rendering"
				}
			}
		}
	}
}
