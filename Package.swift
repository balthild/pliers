// swift-tools-version:6.3
import PackageDescription

let package = Package(
	name: "pliers",
	products: [
		.executable(name: "pliers", targets: ["Pliers"])
	],
	dependencies: [
		.package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
		.package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
		.package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
		.package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.33.0"),
		.package(url: "https://github.com/swift-server/swift-webauthn.git", from: "1.0.0-beta.1"),
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
				.product(name: "Leaf", package: "leaf"),
				.product(name: "JWT", package: "jwt"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "NIOCore", package: "swift-nio"),
				.product(name: "NIOPosix", package: "swift-nio"),
				.product(name: "WebAuthn", package: "swift-webauthn"),
				.target(name: "PliersCommon"),
			],
			swiftSettings: swiftSettings,
		),
		.target(
			name: "PliersCommon",
			dependencies: [],
			swiftSettings: swiftSettings,
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
