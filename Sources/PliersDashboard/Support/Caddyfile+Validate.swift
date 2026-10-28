import Path
import PliersCommon
import Subprocess

extension Caddyfile {
	/// Validates a generated `Caddyfile` with `caddy validate`, deleting `dir` when it is invalid.
	///
	/// `su` runs the check as the caddy user, matching production; tests leave it off so the check
	/// needs no root.
	static func validate(dir: Path, su: Bool = false) async throws {
		let file = dir / "Caddyfile"

		let result = try await Subprocess.run(
			.path(C.caddy.exec),
			arguments: ["validate", "--config", file.string],
			environment: .custom([]),
			platformOptions: su ? try .su(C.caddy.user) : PlatformOptions(),
			input: .none,
			output: .discarded,
			error: .sequence,
			body: { try await $0.standardError.lastLine() },
		)

		guard case .exited(0) = result.terminationStatus else {
			try? dir.delete()
			throw RuntimeError(result.closureResult)
		}
	}
}
