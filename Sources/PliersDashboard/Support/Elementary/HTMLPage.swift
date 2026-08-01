import Elementary

protocol HTMLPage: Sendable, HTML {
	associatedtype Layout: HTMLLayout where Layout.Page == Self
	associatedtype PageHead: HTML
	associatedtype PageBody: HTML

	var layout: Layout { get }
	var title: String { get }

	func head() throws -> sending PageHead
	func body() throws -> sending PageBody
}

extension HTMLPage {
	@HTMLBuilder
	func head() throws -> sending some HTML {}

	static func _render<Renderer: _HTMLRendering>(
		_ html: consuming Self,
		into renderer: inout Renderer,
		with context: consuming _RenderingContext,
	) {
		let result = Result { try Assembly(html) }
		switch result {
		case .success(let assembly):
			Assembly._render(assembly, into: &renderer, with: context)
		case .failure(let error):
			let document = html.layout.error(error)
			Layout.Error._render(document, into: &renderer, with: context)
		}
	}

	@_unavailableInEmbedded
	static func _render<Renderer: _AsyncHTMLRendering>(
		_ html: consuming Self,
		into renderer: inout Renderer,
		with context: consuming _RenderingContext,
	) async throws {
		let result = Result { try Assembly(html) }
		switch result {
		case .success(let assembly):
			try await Assembly._render(assembly, into: &renderer, with: context)
		case .failure(let error):
			let document = html.layout.error(error)
			try await Layout.Error._render(document, into: &renderer, with: context)
		}
	}
}

private struct Assembly<Page: HTMLPage>: HTMLDocument {
	let title: String
	let head: Page.Layout.Head
	let body: Page.Layout.Body

	init(_ page: borrowing Page) throws {
		self.title = page.layout.title(page)
		self.head = try page.layout.head(page)
		self.body = try page.layout.body(page)
	}
}
