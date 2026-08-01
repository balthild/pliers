import Path
import Testing

@testable import PliersCommon

@Test func testConfigStoresValues() {
	let state = Path("/tmp")!
	let config = Config(port: 7577, state: state)

	#expect(config.port == 7577)
	#expect(config.state.string == state.string)
}
