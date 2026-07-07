import Path
import PliersCommon
import Subprocess
import Vapor

struct CaddyConfigController: RouteCollection {
	func boot(routes: any RoutesBuilder) throws {
		let group = routes.grouped(User.requireLoggedIn())

		group.group("caddy", "config") { group in
			group.post("apply", use: self.apply)
		}
	}

	func apply(req: Request) async throws -> Response {
		let dir = try await generate(req: req)

		try await Result { try await validate(dir: dir) }
			.alert("invalid caddy config generated")

		defer { try? dir.delete() }

		let live = dir.parent / "live"
		try live.replace(with: dir)

		return req.redirect(.back)
	}

	private func generate(req: Request) async throws -> Path {
		let dir = try mkdir()

		let sites = try await Caddy.query(on: req.db).all()

		let caddyfile = Caddyfile.build {
			Caddyfile.item {
				Caddyfile.item("admin", "off")
			}

			for site in sites {
				let scheme = site.config.tls == nil ? "http://" : "https://"
				let listeners = site.domains.map { "\(scheme)\($0)" }.joined(separator: ", ")

				Caddyfile.item(listeners) {
					switch site.config.tls {
					case .acme:
						Caddyfile.empty()
					case .file(let file):
						Caddyfile.item("tls", file.cert.quoteCaddy, file.key.quoteCaddy)
					case .none:
						Caddyfile.empty()
					}

					switch site.config.backend {
					case .proxy(let proxy):
						Caddyfile.item("reverse_proxy", proxy.upstream.quoteCaddy)

					case .file(let file):
						Caddyfile.item("file_server") {
							Caddyfile.item("root", file.root.quoteCaddy)
						}

					case .php(let php):
						Caddyfile.item("php_fastcgi", php.fpm.quoteCaddy) {
							Caddyfile.item("root", php.root.quoteCaddy)
						}

					case .none:
						Caddyfile.item("respond", "It works!".quoteCaddy)
					}

					Caddyfile.item(site.config.custom)
				}
			}
		}

		let file = dir / "Caddyfile"
		let buffer = req.byteBufferAllocator.buffer(string: caddyfile)
		try await req.fileio.writeFile(buffer, at: file.string)

		return dir
	}

	private func validate(dir: Path) async throws {
		let file = dir / "Caddyfile"

		let result = try await Subprocess.run(
			.path(.init(.init(Constants.caddy.exec.string))),
			arguments: .init(["validate", "--config", file.string]),
			environment: .custom([]),
			platformOptions: try .su(Constants.caddy.user),
			input: .none,
			output: .discarded,
			error: .sequence,
		) { execution in
			var last: String = ""

			for try await line in execution.standardError.strings() {
				if !line.isEmpty {
					last = line
				}
			}

			return last
		}

		guard case .exited(0) = result.terminationStatus else {
			try? dir.delete()
			throw RuntimeError(result.closureResult)
		}
	}

	private func mkdir() throws -> Path {
		let base = Constants.caddy.conf / "pliers"
		try base.mkdir(.p)

		for _ in 0..<3 {
			do {
				let dir = base / UUID().uuidString.lowercased()

				// Path.mkdir does not fail when the directory exists
				try FileManager.default.createDirectory(
					at: dir.url,
					withIntermediateDirectories: false,
				)

				return dir
			} catch let error as NSError where error.isFileExistsError {
				continue
			}
		}

		throw RuntimeError("unbelievable")
	}
}
