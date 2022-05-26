let program_artifact_ex1 = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "ex1-a", version: "1.0.0", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "ex1-a", constraint: .any, depType: .prod)])
])

let program_artifact_ex2 = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "ex2-ms", version: "1.0.0", dependencies: []),
    .publish(package: "ex2-ms", version: "2.1.0", dependencies: []),
    .publish(package: "ex2-ms", version: "2.1.2", dependencies: []),
    .publish(package: "ex2-debug", version: "4.3.4", dependencies: [
        DependencyExpr(packageToDependOn: "ex2-ms", constraint: .exactly("2.1.2"), depType: .prod)
    ]),
    .solve(inContext: "ctx", constraints: [
        DependencyExpr(packageToDependOn: "ex2-debug", constraint: .any, depType: .prod), 
        DependencyExpr(packageToDependOn: "ex2-ms", constraint: .lt("2.1.2"), depType: .prod)
    ])
])


let program_artifact_ex3 = EcosystemProgram(declaredContexts: ["ctx"], ops: [

    .publish(package: "ex3-a", version: "1.0.0", dependencies: []),
    .publish(package: "ex3-a", version: "2.0.0", dependencies: [DependencyExpr(packageToDependOn: "ex3-b", constraint: .any, depType: .prod)]),
    .publish(package: "ex3-b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "ex3-a", constraint: .exactly("2.0.0"), depType: .prod)]),

    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "ex3-a", constraint: .any, depType: .prod)])
])


let program_artifact_ex4 = EcosystemProgram(declaredContexts: ["ctx"], ops: [

    .publish(package: "ex4-a", version: "1.0.0", dependencies: []),
    .publish(package: "ex4-a", version: "2.0.0", dependencies: [DependencyExpr(packageToDependOn: "ex4-b", constraint: .exactly("9.9.9"), depType: .prod)]),
    .publish(package: "ex4-b", version: "1.0.0", dependencies: []),

    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "ex4-a", constraint: .any, depType: .prod)])
])

let program_artifact_ex5 = EcosystemProgram(declaredContexts: ["ctx"], ops: [

    .publish(package: "ex5-b", version: "1.0.0", dependencies: []),
    .publish(package: "ex5-b", version: "2.0.0", dependencies: []),
    .publish(package: "ex5-c", version: "1.0.0", dependencies: []),
    .publish(package: "ex5-c", version: "2.0.0", dependencies: []),

    .publish(package: "ex5-a", version: "1.0.0", dependencies: [
        DependencyExpr(packageToDependOn: "ex5-b", constraint: .exactly("2.0.0"), depType: .prod), 
        DependencyExpr(packageToDependOn: "ex5-c", constraint: .exactly("2.0.0"), depType: .prod)
    ]),
    .publish(package: "ex5-a", version: "2.0.0", dependencies: [
        DependencyExpr(packageToDependOn: "ex5-b", constraint: .exactly("1.0.0"), depType: .prod), 
        DependencyExpr(packageToDependOn: "ex5-c", constraint: .exactly("1.0.0"), depType: .prod)
    ]),

    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "ex5-a", constraint: .any, depType: .prod)])
])