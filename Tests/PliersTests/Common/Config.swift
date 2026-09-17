import Path
import PliersCommon
import Testing

@Test func testConfigStoresValues() throws {
	let state = Path("/tmp")!
	let config = try Config(port: 7577, state: state)

	#expect(config.port == 7577)
	#expect(config.state.string == state.string)
}
