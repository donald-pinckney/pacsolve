
let program_AnyVersionMax = EcosystemProgram(declaredContexts: ["ctx"], ops: [
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

/*
 ["yarn2", "cargo", "pip", "npm", "yarn1"]
 success([success(a v2.1.0)])
 */



let program_Max1OrMax2 = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "c", version: "1.0.0", dependencies: []),
    .publish(package: "c", version: "1.0.1", dependencies: []),
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0")), DependencyExpr(packageToDependOn: "c", constraint: .exactly("1.0.0"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "b", constraint: .any), DependencyExpr(packageToDependOn: "c", constraint: .any)])
])

/*
 ["pip", "cargo"]
 a v1.0.1
   b v1.0.0
   c v1.0.0
 b v1.0.0
 c v1.0.0
 
 ["npm", "yarn2", "yarn1"]
 a v1.0.1
   b v1.0.0
   c v1.0.0
 b v1.0.1
 c v1.0.1
 */



let program_Max1OrMax2_LexicalReorder = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: []),
    .publish(package: "c", version: "1.0.0", dependencies: []),
    .publish(package: "c", version: "1.0.1", dependencies: []),
    .publish(package: "b", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0")), DependencyExpr(packageToDependOn: "c", constraint: .exactly("1.0.0"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any), DependencyExpr(packageToDependOn: "a", constraint: .any), DependencyExpr(packageToDependOn: "c", constraint: .any)])
])

/*
 ["pip"]
 a v1.0.0
 b v1.0.1
   a v1.0.0
   c v1.0.0
 c v1.0.0

 ["yarn1", "npm", "yarn2"]
 a v1.0.1
 b v1.0.1
   a v1.0.0
   c v1.0.0
 c v1.0.1

 ["cargo"]
 a v1.0.1
 b v1.0.0       I don't know why cargo doesn't include a and c as dependencies of b here!
 c v1.0.1
 */



let program_Max1OrMax2_DepReorder = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "c", version: "1.0.0", dependencies: []),
    .publish(package: "c", version: "1.0.1", dependencies: []),
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0")), DependencyExpr(packageToDependOn: "c", constraint: .exactly("1.0.0"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any), DependencyExpr(packageToDependOn: "c", constraint: .any), DependencyExpr(packageToDependOn: "a", constraint: .any)])
])

/*
 ["pip", "cargo"]
 a v1.0.1
   b v1.0.0
   c v1.0.0
 b v1.0.0
 c v1.0.0
 
 ["npm", "yarn2", "yarn1"]
 a v1.0.1
   b v1.0.0
   c v1.0.0
 b v1.0.1
 c v1.0.1
 */
