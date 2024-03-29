// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dep = Target.Dependency.product(name: "SimpleEncryptor", package: "CryptoExtensions")

let package = Package(
	name: "SwiftExtensions",
	platforms: [.iOS(.v13), .macOS(.v11)],
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(name: "BasicExtensions", targets: ["BasicExtensions"]),
		.library(name: "StorageExtensions", targets: ["StorageExtensions"]),
		//		.library(name: "CryptoExtensions", targets: ["CryptoExtensions"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/gal-yedidovich/CryptoExtensions", from: "1.0.0")
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(name: "BasicExtensions"),
		//		.target(name: "CryptoExtensions", dependencies: ["BasicExtensions"]),
		.target(name: "StorageExtensions", dependencies: ["BasicExtensions", dep]),
		.testTarget(name: "BasicExtensionsTests", dependencies: ["BasicExtensions"]),
		//		.testTarget(name: "CryptoTests", dependencies: ["CryptoExtensions"]),
		.testTarget(name: "StorageTests", dependencies: ["BasicExtensions", "StorageExtensions"]),
	]
)


