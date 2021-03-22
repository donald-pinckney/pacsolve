import Foundation

let main = MainPackage()
let a = Package(name: "a", versions: ["0.0.1", "0.0.2"])
let b = Package(name: "b", versions: ["0.0.1", "0.0.2"])

let deps = dependencies(
    main.dependsOn(
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

//print(Cargo().generate(dependencies: deps).solve())

let resultGroups = deps.solveUsingAllPackageManagers()


print()
for (result, group) in resultGroups {
    print(group)
    print(result)
    print()
}









