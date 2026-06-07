import Elementary

extension UI.Layout {
	struct Base: HTML {
		let children: any HTML

		var body: any HTML {
			children
		}
	}
}
