import Foundation


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
    
//print(Pip().generate(dependencies: deps).solve())
//print(Npm().generate(dependencies: deps).solve())

print(Npm().generate(dependencies: deps).solve())

