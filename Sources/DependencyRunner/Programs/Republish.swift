let program_Republish = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .yank(package: "a", version: "0.0.1"),
    .publish(package: "a", version: "0.0.1", dependencies: []),
])

/*
 ["npm-real", "yarn1-real", "yarn2-real", "cargo-real", "pip-real"]
 ERROR on 2nd publish

 */
