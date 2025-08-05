// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "RealtimeKitUI",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "RealtimeKitUI", targets: ["RealtimeKitUI"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/dyte-in/RealtimeKitCoreiOS.git",
      revision: "5473910f19a62a96c9b7cdd8d9c08f6829f560ea")
  ],
  targets: [
    .target(
      name: "RealtimeKitUI",
      path: "RealtimeKitUI/",
      dependencies: [
        "RealtimeKit",
        "RTKWebRTC",
      ],
      resources: [
        .process("Resources/notification_join.mp3"),
        .process("Resources/notification_message.mp3"),
      ])
  ]
)
