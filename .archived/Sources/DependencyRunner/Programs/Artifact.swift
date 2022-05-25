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

