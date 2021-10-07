
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
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
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
    .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"), depType: .prod), DependencyExpr(packageToDependOn: "c", constraint: .exactly("1.0.0"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "c", constraint: .any, depType: .prod)])
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
    .publish(package: "b", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "a", constraint: .exactly("1.0.0"), depType: .prod), DependencyExpr(packageToDependOn: "c", constraint: .exactly("1.0.0"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "c", constraint: .any, depType: .prod)])
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
    .publish(package: "a", version: "1.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"), depType: .prod), DependencyExpr(packageToDependOn: "c", constraint: .exactly("1.0.0"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "c", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod)])
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



let program_MinNumPackages = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "c", version: "1.0.0", dependencies: []),
    .publish(package: "d", version: "1.0.0", dependencies: []),
    .publish(package: "e", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "1.0.0", dependencies: []),
    .publish(package: "a", version: "1.0.1", dependencies: [
                DependencyExpr(packageToDependOn: "b", constraint: .exactly("1.0.0"), depType: .prod),
                DependencyExpr(packageToDependOn: "c", constraint: .exactly("1.0.0"), depType: .prod),
                DependencyExpr(packageToDependOn: "d", constraint: .exactly("1.0.0"), depType: .prod),
                DependencyExpr(packageToDependOn: "e", constraint: .exactly("1.0.0"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any, depType: .prod), DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod)])
])

/*
 ["yarn1", "yarn2", "npm"]
 a v1.0.1
   b v1.0.0
   c v1.0.0
   d v1.0.0
   e v1.0.0
 b v1.0.1

 ["pip", "cargo"]
 a v1.0.1
   b v1.0.0
   c v1.0.0
   d v1.0.0
   e v1.0.0
 b v1.0.0
 */
