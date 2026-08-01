import Foundation
import Testing

@testable import PliersCommon

@Test func testIsFileExistsErrorForPOSIX() {
	let error = NSError(domain: NSPOSIXErrorDomain, code: Int(EEXIST))
	#expect(error.isFileExistsError)
}

@Test func testIsFileExistsErrorForCocoa() {
	let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError)
	#expect(error.isFileExistsError)
}

@Test func testIsFileExistsErrorFalseForOtherErrors() {
	let error = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))
	#expect(!error.isFileExistsError)
}
