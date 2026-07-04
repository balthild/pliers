import Foundation

extension NSError {
	public var isFileExistsError: Bool {
		return (domain == NSPOSIXErrorDomain && code == EEXIST)
			|| (domain == NSCocoaErrorDomain && code == NSFileWriteFileExistsError)
	}
}
