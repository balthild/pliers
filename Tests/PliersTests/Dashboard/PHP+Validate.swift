import Testing

@testable import PliersDashboard

@Test func testPHPListenAddressAcceptsValid() {
	#expect("127.0.0.1:9000".isPHPListenAddress)
	#expect("0.0.0.0:9000".isPHPListenAddress)
	#expect("localhost:9000".isPHPListenAddress)
	#expect("my-php-host.internal:8080".isPHPListenAddress)
	#expect("[::1]:9000".isPHPListenAddress)
	#expect("[2001:db8::1]:9000".isPHPListenAddress)
	#expect("127.0.0.1:1".isPHPListenAddress)
	#expect("127.0.0.1:65535".isPHPListenAddress)
}

@Test func testPHPListenAddressRejectsInvalid() {
	#expect("127.0.0.1".isPHPListenAddress == false)
	#expect(":9000".isPHPListenAddress == false)
	#expect("127.0.0.1:".isPHPListenAddress == false)
	#expect("127.0.0.1:0".isPHPListenAddress == false)
	#expect("127.0.0.1:65536".isPHPListenAddress == false)
	#expect("127.0.0.1:123456".isPHPListenAddress == false)
	#expect("127.0.0.1:abc".isPHPListenAddress == false)
	#expect("127.0.0.1 :9000".isPHPListenAddress == false)
	#expect(";rm -rf /:9000".isPHPListenAddress == false)
	#expect("".isPHPListenAddress == false)
}

@Test func testPHPListenAddressRejectsInjection() {
	#expect("127.0.0.1:9000\nuser = root".isPHPListenAddress == false)
	#expect("127.0.0.1:9000\n".isPHPListenAddress == false)
	#expect("unix//run/x.sock".isPHPListenAddress == false)
}

@Test func testPHPSizeValueAcceptsValid() {
	#expect("-1".isPHPSizeValue)
	#expect("128M".isPHPSizeValue)
	#expect("2G".isPHPSizeValue)
	#expect("512k".isPHPSizeValue)
	#expect("0".isPHPSizeValue)
	#expect("1024".isPHPSizeValue)
}

@Test func testPHPSizeValueRejectsInvalid() {
	#expect("".isPHPSizeValue == false)
	#expect("128MB".isPHPSizeValue == false)
	#expect("M".isPHPSizeValue == false)
	#expect("-2".isPHPSizeValue == false)
	#expect("1.5G".isPHPSizeValue == false)
	#expect("128 M".isPHPSizeValue == false)
	#expect("128M\npost_max_size = 1G".isPHPSizeValue == false)
}
