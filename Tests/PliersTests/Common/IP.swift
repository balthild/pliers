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

@Test func testIsInCIDR() {
	#expect("127.0.0.1".isInCIDR("127.0.0.1/8"))
	#expect("127.1.2.3".isInCIDR("127.0.0.0/8"))
	#expect("10.5.6.7".isInCIDR("10.0.0.0/8"))
	#expect("192.168.1.5".isInCIDR("192.168.1.0/24"))
	#expect("172.31.255.255".isInCIDR("172.16.0.0/12"))
	#expect("::1".isInCIDR("::1/128"))
	#expect("fd00::1".isInCIDR("fd00::/8"))
	#expect("1.2.3.4".isInCIDR("0.0.0.0/0"))

	// a bare address matches only itself
	#expect("10.0.0.1".isInCIDR("10.0.0.1"))
	#expect("10.0.0.1".isInCIDR("10.0.0.2") == false)

	// outside the block
	#expect("10.0.0.1".isInCIDR("10.1.0.0/16") == false)
	#expect("192.168.2.1".isInCIDR("192.168.1.0/24") == false)

	// different families never match
	#expect("127.0.0.1".isInCIDR("::1/128") == false)
	#expect("::1".isInCIDR("127.0.0.1/8") == false)

	// malformed values fail closed
	#expect("10.0.0.1".isInCIDR("10.0.0.0/33") == false)
	#expect("10.0.0.1".isInCIDR("10.0.0.0/") == false)
	#expect("10.0.0.1".isInCIDR("not-a-cidr") == false)
	#expect("not-an-ip".isInCIDR("10.0.0.0/8") == false)
}
