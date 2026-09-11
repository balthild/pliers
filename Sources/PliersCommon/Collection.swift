extension Collection {
	public subscript(maybe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}
