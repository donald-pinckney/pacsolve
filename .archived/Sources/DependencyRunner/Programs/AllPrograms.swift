import Foundation

let ALL_PROGRAMS: [String : EcosystemProgram] = [
    "ManagersWork": managersWork,
    "AnyVersionMax": program_AnyVersionMax,
    "ObviousSingleResolution": program_obviousSingleResolution,
    "ObviousSingleResolutionPre": program_obviousSingleResolutionPre,
    "CrissCross": program_CrissCross,
    "CrissCrossPre": program_CrissCrossPre,
    "TreeResolution": program_TreeResolution,
    "TreeResolutionPre": program_TreeResolutionPre,
    "DoublePublish": program_DoublePublish,
    "DoubleYank": program_DoubleYank,
    "PublishOutOfOrderBug": program_PublishOutOfOrderBug,
    "PublishOutOfOrderMinor": program_PublishOutOfOrderMinor,
    "PublishOutOfOrderMinorBug": program_PublishOutOfOrderMinorBug,
    "PublishOutOfOrderMajor": program_PublishOutOfOrderMajor,
    "Republish": program_Republish,
    "PublishWithNonexistentDep": program_PublishWithNonexistentDep,
    "PublishWithNonexistentDepVersion": program_PublishWithNonexistentDepVersion,
    "PublishWithYankedDep": program_PublishWithYankedDep,
    "PublishThenYankDep": program_PublishThenYankDep,
    "CanPublishStar": program_PublishStar,
    "PublishSelfDep": program_PublishSelfDep,
    "Publish2Cycle": program_Publish2Cycle,
    "PublishOldVersionSelfCycle": program_PublishOldVersionSelfCycle,
    "FreshExactDepOnYank": program_FreshExactDepOnYank,
    "FreshAnyDepOnYank": program_FreshAnyDepOnYank,
    "SolveYankSolve": program_SolveYankSolve,
    "Max1OrMax2": program_Max1OrMax2,
    "Max1OrMax2_LexicalReorder": program_Max1OrMax2_LexicalReorder,
    "Max1OrMax2_DepReorder": program_Max1OrMax2_DepReorder,
    "MinNumPackages": program_MinNumPackages,
    "LocalStoreTryAnyUpdate": program_LocalStoreTryAnyUpdate,
    "LocalStoreForceChange": program_LocalStoreForceChange,
    "ChangeInstalledVersion": program_ChangeInstalledVersion,
    "TreeOrDagDifferent": program_TreeOrDagDifferent,
    "TreeOrDagSame": program_TreeOrDagSame,
    "SubDependencyBlocked": program_SubDependencyBlocked,
    "TestC_Exactly": program_TestC_Exactly,
    "TestC_Geq": program_TestC_Geq,
    "TestC_Gt": program_TestC_Gt,
    "TestC_Leq": program_TestC_Leq,
    "TestC_Lt": program_TestC_Lt,
    "TestC_Caret": program_TestC_Caret,
    "TestC_Tilde": program_TestC_Tilde,
    "TestC_AndRange": program_TestC_AndRange,
    "TestC_AndComplex": program_TestC_AndComplex,
    "TestC_AndCNF": program_TestC_AndCNF,
    "TestC_OrRange": program_TestC_OrRange,
    "TestC_AndOr": program_TestC_AndOr,
    "TestC_OrAnd": program_TestC_OrAnd,
    "TestC_WildcardBug": program_TestC_WildcardBug,
    "TestC_WildcardMinor": program_TestC_WildcardMinor,
    "TestC_WildcardMajor": program_TestC_WildcardMajor,
    "TestC_NotExactly": program_TestC_NotExactly,
    "TestC_NotWildcardBug": program_TestC_NotWildcardBug,
    "TestC_NotWildcardMinor": program_TestC_NotWildcardMinor,
    "TestC_NotWildcardMajor": program_TestC_NotWildcardMajor,
    "TestC_NotExactlyAll": program_TestC_NotExactlyAll,
    "Transitive": program_Transitive,
    "WeirdGraph": program_WeirdGraph,
    "WeirdCycle": program_WeirdCycle,
    "ShareNode": program_ShareNode,
    "BadDep": program_BadDep,
    "AllThreeDifferent": program_AllThreeDifferent,
    "RandomExampleEmptyConstraints" : generateRandomExampleEmptyConstraints(numPackages: 3, numVersions: 5),
    "RandomExampleAnyConstraints" : generateRandomExampleAnyConstraints(numPackages: 3, numVersions: 5, numDeps: 2),

    "ArtifactEx1": program_artifact_ex1,
    "ArtifactEx2": program_artifact_ex2,
    "ArtifactEx3": program_artifact_ex3,
    "ArtifactEx4": program_artifact_ex4,
    "ArtifactEx5": program_artifact_ex5,
]





let ALL_MANAGERS: [String : () -> AnyPackageManager] = [
    "pip": { Pip().eraseTypes() },
    "pip-real": { PipReal().eraseTypes() },
    "npm": { Npm().eraseTypes() },
    "npm-real": { NpmReal().eraseTypes() },
    "yarn1": { Yarn1().eraseTypes() },
    "yarn1-real": { Yarn1Real().eraseTypes() },
    "yarn2": { Yarn2().eraseTypes() },
    "yarn2-real": { Yarn2Real().eraseTypes() },
    "cargo": { Cargo().eraseTypes() },
    "cargo-real": { CargoReal().eraseTypes() },
    "external-rosette": { ExternalPackageManager(name: "external-rosette", baseCommand: ["PythonSolvingHarness/main.sh"]).eraseTypes() }
]

let ALL_LOCAL_MANAGER_NAMES: [String] = ALL_MANAGERS.keys.filter { !$0.hasSuffix("-real") }
let ALL_REAL_MANAGER_NAMES: [String] = ALL_MANAGERS.keys.filter { $0.hasSuffix("-real") }


@discardableResult
func runProgramWithPackageManagers(managerNames: [String], program: EcosystemProgram, funcName: String = #function, iTerm2: Bool = false) -> [ExecutionResult<AnyHashable> : Set<String>] {
    
    let managers = managerNames.map { ALL_MANAGERS[$0]!() }
    
    let resultGroups = managers
        .map { pm -> (ExecutionResult<AnyHashable>, String) in
            Logger.log(startPackageManager: pm.uniqueName)
            return (pm.run(program) , pm.uniqueName) }
        .reduce(into: [:]) { ( groups: inout [ExecutionResult<AnyHashable> : Set<String>], result_name) in
            let (result, name) = result_name
            groups[result, default: []].insert(name)
        }

    
    let renderDir = GenDirManager(baseName: "renders")

    print("Test \(funcName) results:")
    for (result, group) in resultGroups {
        print(group)
        switch result {
        case .failure(let err):
            print("Execution error: \(err)")
        case .success(let graphs):
            let graphDescs = graphs.map { g in
                do {
                    return try g.graphDescription(inDirectory: renderDir, hasIterm2: iTerm2)
                } catch {
                    return "Error rendering graph: \(error)"
                }
            }.joined(separator: ",\n")
            print("[\n\(graphDescs)\n]")
        }
        print()
    }
    print("------------------------------------\n\n")

    return resultGroups
}


@discardableResult
func runProgramWithAllPackageManagers(program: EcosystemProgram, funcName: String = #function, iTerm2: Bool = false) -> [ExecutionResult<AnyHashable> : Set<String>] {
    let allPackageManagers: [String]
    if shouldRunReal() {
        allPackageManagers = ALL_LOCAL_MANAGER_NAMES + ALL_REAL_MANAGER_NAMES
    } else {
        allPackageManagers = ALL_LOCAL_MANAGER_NAMES
    }
    
    return runProgramWithPackageManagers(managerNames: allPackageManagers, program: program, funcName: funcName, iTerm2: iTerm2)
}

@discardableResult
func runProgramWithPackageManagers(managerNames: [String], programName: String, funcName: String = #function, iTerm2: Bool = false) -> [ExecutionResult<AnyHashable> : Set<String>] {
    runProgramWithPackageManagers(managerNames: managerNames, program: ALL_PROGRAMS[programName]!, funcName: funcName, iTerm2: iTerm2)
}

@discardableResult
func runProgramWithAllPackageManagers(programName: String, funcName: String = #function, iTerm2: Bool = false) -> [ExecutionResult<AnyHashable> : Set<String>] {
    runProgramWithAllPackageManagers(program: ALL_PROGRAMS[programName]!, funcName: funcName, iTerm2: iTerm2)
}


func shouldRunReal() -> Bool {
    guard let enableStr = ProcessInfo.processInfo.environment["ENABLE_REAL_REGISTRIES"] else {
        return false
    }
    return enableStr.lowercased() == "true" || enableStr.lowercased() == "yes" || enableStr.lowercased() == "1"
}
