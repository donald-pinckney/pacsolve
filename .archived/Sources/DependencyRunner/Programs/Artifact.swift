let program_artifact_ex1 = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "ex1-a", version: "1.0.0", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "ex1-a", constraint: .any, depType: .prod)])
])

