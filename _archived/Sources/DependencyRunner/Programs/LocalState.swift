let program_LocalStoreTryAnyUpdate = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)]),
    .publish(package: "a", version: "0.0.2", dependencies: []),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)]),
])

/*
 ["npm", "pip", "yarn1", "yarn2", "cargo"]
 success([success(a v0.0.1), success(a v0.0.1)])
 */



let program_LocalStoreForceChange = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.1", dependencies: []),
    .publish(package: "a", version: "1.0.2", dependencies: []),
    
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "b", version: "1.0.2", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.2"), depType: .prod)]),

    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.1"), depType: .prod)]),
])

/*
 ["pip", "cargo"]
 b v1.0.2
   a v1.0.2
 
 a v1.0.1
 b v1.0.1

 
 ["yarn2", "yarn1", "npm"]
 b v1.0.2
   a v1.0.2
 
 a v1.0.1
 b v1.0.2
   a v1.0.2
 */



let program_ChangeInstalledVersion = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.1", dependencies: []),
    .publish(package: "a", version: "1.0.2", dependencies: []),

    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.1"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.2"), depType: .prod)])
])

/*
 ["yarn1", "yarn2", "cargo", "npm", "pip"]
 success([success(a v1.0.1), success(a v1.0.2)])
 */

