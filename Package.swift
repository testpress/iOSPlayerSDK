// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TPStreamsSDK",
  platforms: [
    .iOS(.v12),
  ],
  products: [
    .library(
      name: "TPStreamsSDK",
      targets: ["TPStreamsSDK"])
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
    .package(url: "https://github.com/M3U8Kit/M3U8Parser", .upToNextMajor(from: "1.1.0")),
    .package(url: "https://github.com/ashleymills/Reachability.swift", .upToNextMajor(from: "5.2.2")),
    .package(url: "https://github.com/realm/realm-swift", exact: "10.54.2")
  ],

  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "TPStreamsSDK",
      dependencies: [
        "Alamofire",
        "M3U8Kit",
        .product(name: "Reachability", package: "Reachability.swift"),
        .product(name: "RealmSwift", package: "realm-swift")
      ],
      path: "Source",
      resources: [
        .process("PrivacyInfo.xcprivacy")],
      swiftSettings: [
        .define("SPM")
      ]
    ),
    .testTarget(
      name: "iOSPlayerSDKTests",
      dependencies: ["TPStreamsSDK"],
      path:"Tests")
  ],  
  swiftLanguageVersions: [
    .v5
  ]
)
