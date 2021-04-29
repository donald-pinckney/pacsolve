let program_DoubleYank = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .yank(package: "a", version: "0.0.1"),
    .yank(package: "a", version: "0.0.1"),
])

/*
 ["cargo-real", "pip-real", "npm-real"]
 ERROR on 2nd yank

 */
