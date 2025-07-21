// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdMobKit",
    // Add version for local packages
    defaultLocalization: "en",
    // For local packages, you can add version info in comments or use git tags
    // Version: 1.0.0
    platforms: [
        .iOS(.v15),
        .macOS(.v12), // Add if needed
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AdMobKit",
            targets: ["AdMobKit"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "12.0.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "AdMobKit",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: "Sources/AdMobKit",
            // Add resources if you have any (images, xibs, etc.)
            resources: [
                .process("NativeAdView.xib"),
                .process("Media.xcassets")
            ],
            // Add compiler settings if needed
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        ),
    ]
)
