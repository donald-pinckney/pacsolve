let program_TreeOrDagSame = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "2.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0")), DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"))])
])

/*
 All package managers give a DAG resolution where a@1.0.0 is SHARED.
 Result of `swift run DependencyRunnerMain TreeOrDagSame all`:
 
 ["yarn1", "yarn2", "npm", "pip", "cargo"]
 success([success(
 a v1.0.0  #0
 b v1.0.0  #0
   a v1.0.0  #1)])
 */


let program_TreeOrDagDifferent = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "2.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("2.0.0"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0")), DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"))])
])

/*
 Though of course when a package resolves to DIFFERENT versions, then there is no shared node.
 Result of `swift run DependencyRunnerMain TreeOrDagDifferent all`:
 
 ["npm", "cargo", "yarn1", "yarn2"]
 success([success(
 a v1.0.0  #0
 b v1.0.0  #0
   a v2.0.0  #0)])

 ["pip"]
 success([failure(...)])
 */
