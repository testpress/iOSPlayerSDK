// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TPStreamsSDK",
  platforms: [
    .iOS(.v11),
  ],
  products: [
    .library(
      name: "TPStreamsSDK",
      targets: ["TPStreamsSDK"])
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
    .package(url: "https://github.com/getsentry/sentry-cocoa.git", .upToNextMajor(from: "8.0.0")),
    .package(url: "https://github.com/M3U8Kit/M3U8Parser", .upToNextMajor(from: "1.1.0")),
    .package(url: "https://github.com/ashleymills/Reachability.swift", .upToNextMajor(from: "5.2.2"))
  ],

  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "TPStreamsSDK",
      dependencies: [
        "Alamofire",
        "M3U8Parser",
        .product(name: "Sentry", package: "sentry-cocoa"),
        .product(name: "Reachability", package: "Reachability.swift"),
      ],
      path: "Source",
      swiftSettings: [
        .define("SPM")
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy")]
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
