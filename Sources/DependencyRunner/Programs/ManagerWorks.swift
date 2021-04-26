let managersWork = EcosystemProgram(declaredContexts: ["ctx1", "ctx2"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .solve(inContext: "ctx1", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)]),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .solve(inContext: "ctx2", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)]),
])
