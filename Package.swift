// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Unclog",
    dependencies: [
    .Package(url: "./Pcap", majorVersion: 1),
    ]
)
