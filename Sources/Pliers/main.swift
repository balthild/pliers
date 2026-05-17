import PliersServer

@main
enum Main {
	static func main() async throws {
		try await PliersServer.run()
	}
}
