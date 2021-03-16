let main = MainPackage()
let a = Package(name: "A", versions: ["0.0.1", "0.0.2"])
let b = Package(name: "B", versions: ["0.0.1", "0.0.2"])

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

//print("pip:")
//print(Pip().generate(dependencies: deps).solve())
//
//print("npm:")
//print(Npm().generate(dependencies: deps).solve())
//
//print("yarn1:")
//print(Yarn1().generate(dependencies: deps).solve())
//
//print("yarn2:")
//print(Yarn2().generate(dependencies: deps).solve())

print("cargo:")
print(Cargo().generate(dependencies: deps).solve())

