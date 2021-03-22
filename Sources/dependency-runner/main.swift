import Foundation


func main() {
    testVersionCrissCross()
}
main()



func testVersionCrissCross() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["0.0.1", "0.0.2"])
    let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("0.0.1").dependsOn(
            b == "0.0.2"
        ),
        a.version("0.0.2").dependsOn(
            b == "0.0.1"
        )
    )
    
    runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
}



func runTest(dependencies: Dependencies, usingPackageManagers: [PackageManager], name: String = #function) {
    let resultGroups = dependencies.solveUsingAllPackageManagers()

    print("Test \(name):")
    for (result, group) in resultGroups {
        print(group)
        print(result)
        print()
    }
}









