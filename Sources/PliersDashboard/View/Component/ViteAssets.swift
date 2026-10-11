import Elementary
import Path
import Vapor

extension View.Component {
	struct ViteAssets: HTML {
		@View.Context var req: Request

		let entries: [String]

		var body: some HTML {
			meta(.charset(.utf8))
			meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))

			let assets = self.assets()
			for uri in assets.styles {
				link(.rel(.stylesheet), .href(uri))
			}
			for uri in assets.scripts {
				script(.src(uri), .type(.module), .defer) {}
			}
		}

		private struct Assets {
			var scripts: [String] = []
			var styles: [String] = []
		}

		private func assets() -> Assets {
			let pub = Path(req.application.directory.publicDirectory)
			guard let pub else { return Assets() }

			let assets = try? self.assets(dist: pub / "dist")
			return assets ?? Assets()
		}

		private func assets(dist: Path) throws -> Assets {
			#if DEBUG
				let dev = dist / ".vite/dev"
				print(dev, dev.exists)
				if dev.exists {
					return try self.assets(dist: dist, dev: dev)
				}
			#endif

			let prod = dist / ".vite/manifest.json"
			return try self.assets(dist: dist, prod: prod)
		}

		private func assets(dist: Path, dev: Path) throws -> Assets {
			let base = try String(contentsOf: dev)

			var assets = Assets()
			for entry in entries {
				assets.scripts.append("\(base)/\(entry)")
			}

			return assets
		}

		private struct EntryInfo: Decodable {
			let file: String
			let isEntry: Bool?
			let css: [String]?
		}

		private func assets(dist: Path, prod: Path) throws -> Assets {
			let data = try Data(contentsOf: prod.url)
			let manifest = try JSONDecoder().decode([String: EntryInfo].self, from: data)

			var assets = Assets()
			for entry in entries {
				if let info = manifest[entry] {
					guard info.isEntry == true else { continue }

					assets.scripts.append("/dist/\(info.file)")
					for css in info.css ?? [] {
						assets.styles.append("/dist/\(css)")
					}
				}
			}

			return assets
		}
	}
}
