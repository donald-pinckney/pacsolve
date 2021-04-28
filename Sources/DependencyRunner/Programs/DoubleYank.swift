let program_DoubleYank = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .yank(package: "a", version: "0.0.1"),
    .yank(package: "a", version: "0.0.1"),
])

/*
 ["npm-real", "yarn1-real", "yarn2-real"]
 success
 
 ["cargo-real", "pip-real"]
 ERROR on 2nd yank

 */
