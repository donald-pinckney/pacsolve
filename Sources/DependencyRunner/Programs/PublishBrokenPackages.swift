
let program_PublishWithNonexistentDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])

/*
 ["pip-real", "npm-real"]
 Publish SUCCESS, solve FAIL

 ["cargo-real"]
 Publish FAIL
 */



let program_PublishWithYankedDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "b", version: "0.0.2", dependencies: []),
    .yank(package: "b", version: "0.0.1"),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])

/*
 ["pip-real", "npm-real"]
 Solve success (a@0.0.1, b@0.0.1)

 ["cargo-real"]
 Solve FAIL
 */



let program_PublishThenYankDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.1"))]),
    .yank(package: "b", version: "0.0.1"),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])


let program_PublishWithNonexistentDepVersion = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "b", version: "0.0.1", dependencies: []),
    .publish(package: "a", version: "0.0.1", dependencies: [DependencyExpr(packageToDependOn: "b", constraint: .exactly("0.0.2"))]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "a", constraint: .any)])
])

/*
 ["pip-real", "npm-real", "cargo-real"]
 Publishes SUCCEED, solve FAILS
 */
