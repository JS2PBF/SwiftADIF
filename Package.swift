// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftADIF",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftADIF",
            targets: ["SwiftADIF"]
        ),
        .library(
            name: "ADIParser",
            targets: ["ADIParser"]
        ),
        .library(
            name: "ADIFValidator",
            targets: ["ADIFValidator"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftADIF",
            dependencies: [
                "ADIParser",
                "ADIFValidator",
            ]
        ),
        .target(
            name: "ADIParser",
            dependencies: [
                "ADIFValidator",
            ]
        ),
        .target(
            name: "ADIFValidator"
        ),
        .testTarget(
            name: "SwiftADIFTests",
            dependencies: ["SwiftADIF"],
            resources: [.copy("TestResources")]
        ),
        .testTarget(
            name: "ADIParserTests",
            dependencies: ["ADIParser"],
            resources: [.copy("TestResources")]
        ),
        .testTarget(
            name: "ADIFValidatorTests",
            dependencies: ["ADIFValidator"]
        ),
    ],
    swiftLanguageVersions: [
        .v5,
//        .version("5.7"),
//        .version("5.8"),
    ]
)
