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
		C.services / service
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

		lines.append("listen = \(config.listen.rawValue(version: version))")
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
