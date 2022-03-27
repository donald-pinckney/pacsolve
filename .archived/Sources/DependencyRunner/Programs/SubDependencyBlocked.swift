let program_SubDependencyBlocked = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "1.0.0", dependencies: []), // Suppose that b@1.0.0 has a security vulnerability
    .publish(package: "b", version: "1.0.1", dependencies: []), // And b@1.0.1 contains a patch.
    
    .publish(package: "a", version: "1.0.0", dependencies: [
        DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"), depType: .prod) // And let's suppose that package A keeps it's deps pinned
    ]),
    
    // Then, no matter what we put here, we will get the vulnerable version of B.
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)]),
])

/*
 A dependency which pins it's sub-dependencies does block the root from receiving patches.
 Result of `swift run DependencyRunnerMain SubDependencyBlocked all`:
 
 ["npm", "cargo", "yarn1", "yarn2", "pip"]
 success([success(
 a v1.0.0  #0
   b v1.0.0  #0)])
 
 */
