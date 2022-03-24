let program_PublishStar = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "b", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)]),
])
