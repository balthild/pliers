import Foundation
import NIOCore
import NIOFileSystem
import Path
import PliersShim

extension Path {
	public static func home(for username: String) -> Path? {
		guard let url = FileManager.default.homeDirectory(forUser: username) else {
			return nil
		}

		return .init(url: url)
	}

	public var canonical: Path? {
		let url = self.url.resolvingSymlinksInPath()
		return .init(url: url)
	}

	public var attrs: Result<[FileAttributeKey: Any], Error> {
		return Result {
			try FileManager.default.attributesOfItem(atPath: self.string)
		}
	}

	public func replace(with other: Path) throws {
		let _ = try FileManager.default.replaceItemAt(self.url, withItemAt: other.url)
	}

	public func hasPrefix(_ prefix: Path) -> Bool {
		let longer = self.components
		let shorter = prefix.components
		guard longer.count >= shorter.count else {
			return false
		}

		for (index, component) in shorter.enumerated() {
			if longer[index] != component {
				return false
			}
		}

		return true
	}
}

extension Path {
	public enum RandPathType: String {
		case file = "file"
		case dir = "dir"
	}

	public func mkrand(_ type: RandPathType, retries: Int = 3) throws -> Path {
		for _ in 0..<retries {
			do {
				let path = self / UUID().uuidString.lowercased()

				switch type {
				case .file:
					try Data().write(to: path.url, options: .withoutOverwriting)

				case .dir:
					// Path.mkdir does not fail when the directory exists
					try FileManager.default.createDirectory(
						at: path.url,
						withIntermediateDirectories: false,
					)
				}

				return path
			} catch let error as NSError where error.isFileExistsError {
				continue
			}
		}

		throw RuntimeError("failed to create a unique \(type) after \(retries) retries")
	}
}

extension Path {
	public enum HandleTypeRead { case r }
	public enum HandleTypeWrite { case w }
	public enum HandleTypeReadWrite { case rw }

	public func handle<T>(
		_ type: HandleTypeRead,
		execute: (_ handle: ReadFileHandle) async throws -> T,
	) async throws -> T {
		return try await FileSystem.shared.withFileHandle(
			forReadingAt: .init(self.string),
			execute: execute,
		)
	}

	public func handle<T>(
		_ type: HandleTypeWrite,
		execute: (_ handle: WriteFileHandle) async throws -> T,
	) async throws -> T {
		return try await FileSystem.shared.withFileHandle(
			forWritingAt: .init(self.string),
			execute: execute,
		)
	}

	public func handle<T>(
		_ type: HandleTypeReadWrite,
		execute: (_ handle: ReadWriteFileHandle) async throws -> T,
	) async throws -> T {
		return try await FileSystem.shared.withFileHandle(
			forReadingAndWritingAt: .init(self.string),
			execute: execute,
		)
	}
}

extension Path {
	public struct AccessMode: OptionSet, Sendable {
		public let rawValue: Int32

		public init(rawValue: Int32) {
			self.rawValue = rawValue
		}

		public static let r = Self(rawValue: R_OK)
		public static let w = Self(rawValue: W_OK)
		public static let x = Self(rawValue: X_OK)

		public static let rw: Self = [.r, .w]
		public static let rx: Self = [.r, .x]
		public static let wx: Self = [.w, .x]
		public static let rwx: Self = [.r, .w, .x]
	}

	public func hasAccess(_ mode: AccessMode, by username: String) -> Bool {
		let result = PliersShim::check_access(mode.rawValue, username, self.string)
		return result == 0
	}
}
