import Foundation
import PliersCommon
import Vapor

struct CloudflareNetworks: LifecycleHandler {
	private static let url = "https://api.cloudflare.com/client/v4/ips"
	private static let interval: Duration = .seconds(3600)

	func didBoot(_ app: Application) throws {
		_ = Task.detached(priority: .background) {
			while true {
				do {
					let ranges = try await Self.fetch(client: app.client, logger: app.logger)
					app.cloudflareNetworks = ranges
					app.logger.notice("Updated Cloudflare IP ranges: \(ranges.count)")
				} catch {
					app.logger.error("Failed to update Cloudflare IP ranges: \(error)")
				}

				try? await Task.sleep(for: Self.interval)
			}
		}
	}
}

extension CloudflareNetworks {
	/// Fetches Cloudflare's published IP ranges.
	///
	/// Bad entries are dropped (narrows the trusted set only). An all-bad response fails and keeps
	/// the previous snapshot.
	static func fetch(client: any Client, logger: Logger) async throws -> [String] {
		let response = try await client.get(.init(string: url))
		let payload = try response.content.decode(Payload.self)

		let raw = payload.result.ipv4_cidrs + payload.result.ipv6_cidrs
		let valid = raw.map(\.trimmed).filter(\.isCIDR)

		guard !raw.isEmpty && !valid.isEmpty else {
			throw RuntimeError("cloudflare returned no valid ip ranges")
		}

		if valid.count != raw.count {
			logger.warning("Skipped \(raw.count - valid.count) invalid Cloudflare IP range(s)")
		}

		return valid
	}

	private struct Payload: Codable {
		let result: Result

		struct Result: Codable {
			let ipv4_cidrs: [String]
			let ipv6_cidrs: [String]
		}
	}
}

extension Application {
	private enum CloudflareNetworksKey: StorageKey {
		typealias Value = [String]
	}

	/// The latest Cloudflare IP ranges snapshot, or an empty list before the first update.
	var cloudflareNetworks: [String] {
		get { self.storage[CloudflareNetworksKey.self] ?? [] }
		set { self.storage[CloudflareNetworksKey.self] = newValue }
	}
}
