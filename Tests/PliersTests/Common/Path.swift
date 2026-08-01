import Foundation
import Path
import Testing

@testable import PliersCommon

@Test func testHasPrefix() {
	let path = Path("/tmp/pliers/a")!
	#expect(path.hasPrefix(Path("/tmp")!))
	#expect(path.hasPrefix(Path("/tmp/pliers")!))
	#expect(!path.hasPrefix(Path("/var")!))
}

@Test func testCanonicalResolvesSymlink() throws {
	let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
	let root = Path(url: rootURL)!
	let target = root / "target"
	let link = root / "link"

	try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
	defer { try? FileManager.default.removeItem(at: rootURL) }

	try FileManager.default.createDirectory(atPath: target.string, withIntermediateDirectories: true)
	try FileManager.default.createSymbolicLink(
		atPath: link.string,
		withDestinationPath: target.string,
	)

	let canonical = try link.canonical.expect("canonical should exist")
	#expect(canonical.string == target.string)
}

@Test func testAttrsAndReplace() throws {
	let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
	let root = Path(url: rootURL)!
	let original = root / "original.txt"
	let replacement = root / "replacement.txt"

	try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
	defer { try? FileManager.default.removeItem(at: rootURL) }

	try "old".write(toFile: original.string, atomically: true, encoding: .utf8)
	try "new".write(toFile: replacement.string, atomically: true, encoding: .utf8)

	let attrs = try original.attrs.get()
	#expect(attrs[.size] as? NSNumber == 3)

	try original.replace(with: replacement)
	let contents = try String(contentsOfFile: original.string, encoding: .utf8)
	#expect(contents == "new")
}

@Test func testHomeAndAccess() throws {
	let username = NSUserName()
	let home = try Path.home(for: username).expect("home should exist for current user")
	#expect(home.hasAccess(.r, by: username))
}
