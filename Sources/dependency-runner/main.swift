import Foundation
import Files

func main() {
//    let here = try! Folder(path: ".")
//    for f in here.files.recursive.includingHidden {
//        print(f.path)
////        rewriteTemplate(file: f, substitutions: substitutions)
//    }
    
    testPipWorks()
    testNpmWorks()

    
//    testTreeResolutionPrerelease()
//    testTreeResolution()
//
//    testVersionCrissCrossPrerelease()
//    testVersionCrissCross()
//    
//    testAnyVersionMax()
//
//    testObviousSingleResolutionPrerelease()
//    testObviousSingleResolution()
}
main()

func testPipWorks() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["0.0.1"])
    let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("0.0.1").dependsOn(
            b == "0.0.1"
        )
    )
    
    let resultGroups = runTest(dependencies: deps, usingPackageManagers: [Pip()])
    assert(resultGroups, hasPartitions: [
        ["pip"]
    ])
}

func testNpmWorks() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["0.0.1"])
    let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("0.0.1").dependsOn(
            b == "0.0.1"
        )
    )
    
    let resultGroups = runTest(dependencies: deps, usingPackageManagers: [Npm()])
    assert(resultGroups, hasPartitions: [
        ["npm"]
    ])
}



func testTreeResolutionPrerelease() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["0.0.1"])
    let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("0.0.1").dependsOn(
            b == "0.0.1"
        )
    )
    
    let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
    assert(resultGroups, hasPartitions: [
        ["npm", "yarn1", "yarn2", "cargo"],
        ["pip"]
    ])
}


func testTreeResolution() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["1.0.1"])
    let b = Package(name: "b", versions: ["1.0.1", "1.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("1.0.1").dependsOn(
            b == "1.0.1"
        )
    )
    
    let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
    assert(resultGroups, hasPartitions: [
        ["cargo", "pip"],
        ["npm", "yarn1", "yarn2"]
    ])
}




func testVersionCrissCrossPrerelease() {
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
    
    let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
    assert(resultGroups, hasPartitions: [
        ["npm", "yarn1", "yarn2", "cargo"],
        ["pip"]
    ])
}

func testVersionCrissCross() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["1.0.1", "1.0.2"])
    let b = Package(name: "b", versions: ["1.0.1", "1.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("1.0.1").dependsOn(
            b == "1.0.2"
        ),
        a.version("1.0.2").dependsOn(
            b == "1.0.1"
        )
    )
    
    let resultGroups = runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
    assert(resultGroups, hasPartitions: [
        ["npm", "yarn1", "yarn2"],
        ["pip", "cargo"]
    ])
}












func testAnyVersionMax() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["0.0.1", "0.0.2", "0.1.0", "0.1.1", "0.1.2", "1.0.0", "1.0.1", "2.0.0", "2.0.1", "2.1.0"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any()
        )
    )
    
    runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
}






func testObviousSingleResolutionPrerelease() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["0.0.1"])
    let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("0.0.1").dependsOn(
            b == "0.0.2"
        )
    )
    
    runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
}

func testObviousSingleResolution() {
    let mainPkg = MainPackage()
    let a = Package(name: "a", versions: ["1.0.1"])
    let b = Package(name: "b", versions: ["1.0.1", "1.0.2"])

    let deps = dependencies(
        mainPkg.dependsOn(
            a.any(),
            b.any()
        ),
        a.version("1.0.1").dependsOn(
            b == "1.0.2"
        )
    )
    
    runTest(dependencies: deps, usingPackageManagers: allPackageManagers())
}









@discardableResult
func runTest(dependencies: Dependencies, usingPackageManagers: [PackageManager], name: String = #function) -> [SolveResult : Set<String>] {
    let resultGroups = dependencies.solve(usingPackageManagers: usingPackageManagers)

    print("Test \(name) results:")
    for (result, group) in resultGroups {
        print(group)
        print(result)
        print()
    }
    print("\n\n------------------------------------\n\n")
    
    return resultGroups
}

func assert(_ resultGroups: [SolveResult : Set<String>], hasPartitions: Set<Set<String>>) {
    let givenPartitions = Set(resultGroups.values)
    assert(givenPartitions == hasPartitions)
}



