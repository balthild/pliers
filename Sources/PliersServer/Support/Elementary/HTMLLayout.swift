import Elementary

protocol HTMLLayout: Sendable {
	associatedtype Page: HTMLPage
	associatedtype Error: HTML
	associatedtype Head: HTML
	associatedtype Body: HTML

	func title(_ page: borrowing Page) -> String
	func error(_ error: Swift.Error) -> sending Error
	func head(_ page: borrowing Page) throws -> sending Head
	func body(_ page: borrowing Page) throws -> sending Body
}
