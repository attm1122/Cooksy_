// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Cooksy",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Cooksy",
            targets: ["Cooksy"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "Cooksy",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "RevenueCat", package: "purchases-ios")
            ],
            path: "Sources/Cooksy"
        ),
        .testTarget(
            name: "CooksyTests",
            dependencies: ["Cooksy"],
            path: "Tests/CooksyTests"
        )
    ]
)
