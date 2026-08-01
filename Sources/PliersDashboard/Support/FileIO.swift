import NIOFileSystem
import Vapor

extension FileIO {
	/// Write the buffer to the file at the path. Overwrites the existing contents of the file.
	/// Unlike `writeFile(_:at:)`, this method do not create the file if it does not exist.
	public func fillFile(_ buffer: ByteBuffer, at path: String) async throws {
		try await FileSystem.shared.withFileHandle(
			forWritingAt: .init(path),
			options: .init(existingFile: .truncate, newFile: nil),
		) { handle in
			_ = try await handle.write(contentsOf: buffer, toAbsoluteOffset: 0)
		}
	}
}
