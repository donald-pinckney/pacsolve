let program_BadDep = EcosystemProgram(declaredContexts: ["ctx"], ops: [
    .publish(package: "c", version: "1.0.0", dependencies: []),
    .publish(package: "b", version: "1.0.1", dependencies: []),
    .publish(package: "b", version: "1.0.2", dependencies: [
        DependencyExpr(packageToDependOn: "c", constraint: .exactly("9.9.9"), depType: .prod)]),
    .solve(inContext: "ctx", constraints: [DependencyExpr(packageToDependOn: "b", constraint: .any, depType: .prod)])

])

// Cargo and PIP:
// ctx ---> b@1.0.1

// NPM:
/*

npm ERR! code ETARGET
npm ERR! notarget No matching version found for @wtcbkjbuzrbl/aca2e4b16438ab3d9d97a0f11ff914029312295797b70ec0ef0bfb3b4e@9.9.9.
npm ERR! notarget In most cases you or one of your dependencies are requesting
npm ERR! notarget a package version that doesn't exist.

npm ERR! A complete log of this run can be found in:
npm ERR!     /Users/donaldpinckney/.npm/_logs/2022-04-15T15_32_30_543Z-debug.log

*/
