// swift-tools-version: 5.9
import PackageDescription

// Sources/LorePocketCore の Swift ファイルは lorepocket-ios/ へのシンボリックリンク。
// ロジックの編集先はアプリ側のファイルだけにする。
let package = Package(
    name: "LorePocketCore",
    products: [
        .library(name: "LorePocketCore", targets: ["LorePocketCore"]),
    ],
    targets: [
        .target(name: "LorePocketCore", path: "Sources/LorePocketCore"),
        .testTarget(
            name: "LorePocketCoreTests",
            dependencies: ["LorePocketCore"],
            path: "Tests/LorePocketCoreTests"
        ),
    ]
)
