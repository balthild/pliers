import PliersCommon
import Testing

@Test func testIsIP() {
	#expect("1.2.3.4".isIP)
	#expect("::1".isIP)
	#expect("not-an-ip".isIP == false)
	#expect("1.2.3".isIP == false)
}

@Test func testIsCIDR() {
	#expect("10.0.0.0/8".isCIDR)
	#expect("172.16.0.0/12".isCIDR)
	#expect("2400:cb00::/32".isCIDR)
	#expect("1.2.3.4".isCIDR)

	#expect("10.0.0.0/33".isCIDR == false)
	#expect("2400:cb00::/129".isCIDR == false)
	#expect("10.0.0.0/".isCIDR == false)
	#expect("example.com".isCIDR == false)
}
