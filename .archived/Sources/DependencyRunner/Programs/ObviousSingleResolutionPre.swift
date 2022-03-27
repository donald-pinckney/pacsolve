
let program_obviousSingleResolutionPre = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "b", version: "0.0.2", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod)])
])
