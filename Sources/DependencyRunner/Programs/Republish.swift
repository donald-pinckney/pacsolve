let program_Republish = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .yank(package: "a", version: "0.0.1"),
    .publish(package: "a", version: "0.0.1", dependencies: []),
])

