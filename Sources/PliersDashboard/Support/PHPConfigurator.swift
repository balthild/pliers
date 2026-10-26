import Path
import PliersCommon

/// Generators and path helpers for the PHP-FPM configuration of an installed PHP version.
///
/// The configuration is laid out as:
///
/// - `/etc/pliers/php/<version>/php-fpm.conf`
/// - `/etc/pliers/php/<version>/php.ini`
/// - `/etc/systemd/system/pliers-php-<version>.service`
///
/// The runtime directory `/run/pliers/php/<version>` holds the unix socket.
struct PHPConfigurator {
	let version: PHP.Version

	var binary: Path {
		C.pkgs / "php" / version.string / "php-fpm"
	}

	var base: Path {
		C.conf / "php"
	}

	var dir: Path {
		base / version.string
	}

	var socket: Path {
		C.run / "php" / version.string / "php-fpm.sock"
	}

	var service: String {
		"pliers-php-\(version).service"
	}

	var unit: Path {
		C.system.services / service
	}
}

extension PHPConfigurator {
	func buildFPM(config: PHP.Config) -> String {
		var lines: [String] = []

		lines.append("[global]")
		lines.append("error_log = syslog")
		lines.append("")

		lines.append("[www]")
		lines.append("user = \(C.www.user)")
		lines.append("group = \(C.www.group)")
		lines.append("")

		lines.append("listen = \(config.rawListenAddress(version: version))")
		if case .unix = config.listen {
			lines.append("listen.owner = \(C.www.user)")
			lines.append("listen.group = \(C.www.group)")
			lines.append("listen.mode = 0660")
		}
		lines.append("")

		lines.append("pm = \(config.pm.rawValue)")
		lines.append("pm.max_children = \(config.maxChildren)")
		if config.pm == .dynamic {
			lines.append("pm.start_servers = \(config.startServers)")
			lines.append("pm.min_spare_servers = \(config.minSpareServers)")
			lines.append("pm.max_spare_servers = \(config.maxSpareServers)")
		}

		lines.append("pm.max_requests = \(config.maxRequests)")
		lines.append("")

		lines.append("request_terminate_timeout = \(config.terminateTimeout)")
		lines.append("")

		return lines.joined(separator: "\n")
	}

	func buildINI(config: PHP.Config) -> String {
		var lines: [String] = []

		lines.append("memory_limit = \(config.memoryLimit)")
		lines.append("upload_max_filesize = \(config.uploadMaxFilesize)")
		lines.append("post_max_size = \(config.postMaxSize)")
		lines.append("max_execution_time = \(config.maxExecutionTime)")

		lines.append("")

		return lines.joined(separator: "\n")
	}

	func buildUnit() -> String {
		let fpm = dir / "php-fpm.conf"
		let ini = dir / "php.ini"

		return
			"""
			[Unit]
			Description=Pliers PHP-FPM \(version)
			After=network.target

			[Service]
			Type=simple
			RuntimeDirectory=pliers/php/\(version)
			ExecStart=\(binary.string) --nodaemonize --php-ini \(ini.string) --fpm-config \(fpm.string)
			Restart=always
			RestartSec=0
			LimitNOFILE=65535

			[Install]
			WantedBy=multi-user.target
			""" + "\n"
	}
}

extension String {
	/// Whether the receiver is a `host:port` TCP listen address, e.g. `127.0.0.1:9000` or
	/// `[::1]:9000`, with a port in the range 1–65535.
	///
	/// The listen address is written verbatim into `php-fpm.conf`, and this configuration is
	/// line-oriented: a value containing a newline could inject a directive of its own. Anchoring
	/// the whole value to a single `host:port` token keeps it from escaping its line.
	var isPHPListenAddress: Bool {
		guard
			let match = self.wholeMatch(of: /(\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9._-]+):([0-9]{1,5})/)
		else {
			return false
		}

		guard let port = Int(match.2) else {
			return false
		}

		return (1...65535).contains(port)
	}

	/// Whether the receiver is a PHP ini shorthand size: `-1`, or a non-negative integer with an
	/// optional `K`/`M`/`G` suffix, e.g. `128M` or `2G`.
	var isPHPSizeValue: Bool {
		self.wholeMatch(of: /-1|[0-9]+[KMGkmg]?/) != nil
	}
}
