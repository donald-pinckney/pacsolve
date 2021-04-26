
let program_anyVersionMax = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .publish(package: "a", version: "0.1.0", dependencies: []),
    .publish(package: "a", version: "0.1.1", dependencies: []),
    .publish(package: "a", version: "0.1.2", dependencies: []),
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: []),
    .publish(package: "a", version: "2.0.0", dependencies: []),
    .publish(package: "a", version: "2.0.1", dependencies: []),
    .publish(package: "a", version: "2.1.0", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])
