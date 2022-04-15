let program_BadDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "c", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "b", version: "1.0.2", dependencies: [
        DependencyExpr(packageToDependOn: "c", constraint: .exactly("9.9.9"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod)])

])
