let program_TreeOrDagDifferent = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "2.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("2.0.0"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0")), DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"))])
])


let program_TreeOrDagSame = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "2.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0")), DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"))])
])


