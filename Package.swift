// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SearchOps",
		platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SearchOps",
            targets: ["SearchOps"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/realm/realm-swift.git", .upToNextMajor(from: "10.42.0")),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.4")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.0"))
        
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SearchOps",
            dependencies: [ .product(name: "RealmSwift", package: "realm-swift"),
                            .product(name: "OrderedCollections", package: "swift-collections"),
                            .product(name: "SwiftyJSON", package: "SwiftyJSON")
                
                          ]),
        .testTarget(
            name: "SearchOpsTests",
            dependencies: ["SearchOps"],
            resources: [
                   // Copy Tests/ExampleTests/Resources directories as-is.
                   // Use to retain directory structure.
                   // Will be at top level in bundle.
                   .process("Resources"),
                 ]),
			
	
    ]
)
