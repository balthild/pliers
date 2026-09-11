import AsyncHTTPClient
import Fluent
import Foundation
import NIOCore
import NIOFileSystem
import Path
import PliersCommon
import Queues
import Subprocess

struct InstallPHPJob: AsyncJob {
	struct Payload: Codable {
		let id: UUID
		let version: PHP.Version
	}

	func dequeue(_ ctx: QueueContext, _ payload: Payload) async throws {
		let progress = try await ctx.progress.get(payload.id)
			.alert("progress handle not found")

		let base = C.pkgs / "php"
		try base.mkdir(.p)

		let tmp = try base.mkrand(.dir)

		try await download(
			ctx: ctx,
			version: payload.version,
			component: "fpm",
			directory: tmp,
			bounds: (0.0, 0.5),
			progress: progress,
		)

		try await download(
			ctx: ctx,
			version: payload.version,
			component: "cli",
			directory: tmp,
			bounds: (0.5, 1.0),
			progress: progress,
		)

		try await ctx.db.transaction { db in
			let records = try await PHP.query(on: ctx.db)
				.filter(\.$version == payload.version)
				.count()
			if records == 0 {
				let php = PHP()
				php.version = payload.version
				try await php.save(on: db)
			}

			let dest = base / payload.version.string
			try dest.mkdir()
			try dest.replace(with: tmp)
		}

		await progress.report { data in
			data.status = .done
			data.message = "Installation complete."
		}

		await progress.finish()
	}

	func error(_ ctx: QueueContext, _ error: Error, _ payload: Payload) async throws {
		let progress = await ctx.progress.get(payload.id)

		await progress?.report { data in
			data.status = .error
			data.message = error.localizedDescription
		}

		await progress?.finish()
	}

	private func download(
		ctx: QueueContext,
		version: PHP.Version,
		component: String,
		directory: Path,
		bounds: (Double, Double),
		progress: ProgressHandle,
	) async throws {
		#if arch(arm64)
			let filename = "php-\(version)-\(component)-linux-aarch64.tar.gz"
		#else
			let filename = "php-\(version)-\(component)-linux-x86_64.tar.gz"
		#endif

		let path = directory / filename

		let url = "https://dl.static-php.dev/v3/php-bin/bulk/\(filename)"
		let response = try await ctx.http.execute(
			HTTPClientRequest(url: url),
			timeout: .seconds(3600),
		)

		await progress.report { data in
			data.progress = bounds.0
			data.message = "Downloading \(filename)"
		}

		// an indeterminate progress bar will be shown when the result is negative
		let total = response.headers.first(name: .contentLength).flatMap(Int64.init) ?? -1
		var count: Int64 = 0
		let scale = 0.95 * (bounds.1 - bounds.0)

		try await path.handle(.w, with: ctx.fs) { handle in
			for try await buffer in response.body {
				count += try await handle.write(contentsOf: buffer, toAbsoluteOffset: count)

				await progress.report { data in
					data.progress = Double(count) / Double(total) * scale + bounds.0
				}
			}
		}

		await progress.report { data in
			data.message = "Extracting \(filename)"
		}

		let result = try await Subprocess.run(
			.path(C.coreutils / "tar"),
			arguments: ["-xf", path.string],
			environment: .custom([]),
			workingDirectory: .init(directory.string),
			output: .discarded,
			error: .string(limit: 8192, encoding: UTF8.self),
		)

		guard result.terminationStatus == .exited(0) else {
			throw RuntimeError(result.standardError ?? "unknown error")
		}

		try path.delete()

		await progress.report { data in
			data.progress = bounds.1
			data.message = "Extracted \(filename)"
		}
	}
}
