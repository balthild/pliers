// swift-tools-version:6.3
import PackageDescription

let package = Package(
	name: "pliers",
	dependencies: [
		.package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
		.package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
		.package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
	],
	targets: [
		.executableTarget(
			name: "Pliers",
			dependencies: [
				.target(name: "PliersServer")
			],
			swiftSettings: swiftSettings,
		),
		.target(
			name: "PliersServer",
			dependencies: [
				.product(name: "Fluent", package: "fluent"),
				.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
				.product(name: "Leaf", package: "leaf"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "NIOCore", package: "swift-nio"),
				.product(name: "NIOPosix", package: "swift-nio"),
			],
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
