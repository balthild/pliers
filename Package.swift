// swift-tools-version:6.3
import PackageDescription

let package = Package(
	name: "pliers",
	products: [
		.executable(name: "pliers", targets: ["Pliers"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
		.package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
		.package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.33.0"),
		.package(url: "https://github.com/swift-server/swift-webauthn.git", from: "1.0.0-beta.1"),
		.package(url: "https://github.com/elementary-swift/elementary.git", from: "0.6.0"),
		.package(url: "https://github.com/vapor-community/vapor-elementary.git", from: "0.1.0"),
		.package(url: "https://github.com/mxcl/Path.swift.git", from: "1.6.0"),
		.package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.4.0"),
		.package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "1.8.0"),
		.package(url: "https://github.com/wendylabsinc/dbus.git", from: "0.4.0"),
	],
	targets: [
		.executableTarget(
			name: "Pliers",
			dependencies: [
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
				.target(name: "PliersServer"),
				.target(name: "PliersCommon"),
			],
			swiftSettings: swiftSettings,
		),
		.target(
			name: "PliersServer",
			dependencies: [
				.product(name: "Fluent", package: "fluent"),
				.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
				.product(name: "JWT", package: "jwt"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "NIOCore", package: "swift-nio"),
				.product(name: "NIOPosix", package: "swift-nio"),
				.product(name: "WebAuthn", package: "swift-webauthn"),
				.product(name: "Elementary", package: "elementary"),
				.product(name: "VaporElementary", package: "vapor-elementary"),
				.product(name: "Path", package: "Path.swift"),
				.product(name: "CasePaths", package: "swift-case-paths"),
				.product(name: "DBUS", package: "DBUS"),
				.target(name: "PliersCommon"),
				.target(name: "PliersSystemd"),
			],
			swiftSettings: swiftSettings,
		),
		.target(
			name: "PliersCommon",
			dependencies: [
				.product(name: "Path", package: "Path.swift"),
				.product(name: "Subprocess", package: "swift-subprocess"),
				.target(name: "PliersShim"),
			],
			swiftSettings: swiftSettings,
		),
		.target(
			name: "PliersSystemd",
			dependencies: [
				.product(name: "DBUS", package: "DBUS")
			],
			exclude: ["Systemd1.xml"],
			swiftSettings: [
				.unsafeFlags(["-suppress-warnings"])
			],
		),
		.target(
			name: "PliersShim",
			cSettings: [
				.unsafeFlags(["-Wall", "-Wextra"])
			],
		),
		.testTarget(
			name: "PliersTests",
			dependencies: [
				.target(name: "PliersServer"),
				.product(name: "VaporTesting", package: "vapor"),
			],
			swiftSettings: swiftSettings,
		),
	],
)

let swiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("ExistentialAny")
]
