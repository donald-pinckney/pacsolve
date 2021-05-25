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
    "TestC_WildcardBug": program_TestC_WildcardBug,
    "TestC_WildcardMinor": program_TestC_WildcardMinor,
    "TestC_WildcardMajor": program_TestC_WildcardMajor,
    "TestC_NotExactly": program_TestC_NotExactly,
    "TestC_NotWildcardBug": program_TestC_NotWildcardBug,
    "TestC_NotWildcardMinor": program_TestC_NotWildcardMinor,
    "TestC_NotWildcardMajor": program_TestC_NotWildcardMajor,
    "TestC_NotExactlyAll": program_TestC_NotExactlyAll
]







let ALL_MANAGERS: [String : () -> InternalPackageManager] = [
    "pip": Pip,
    "pip-real": PipReal,
    "npm": Npm,
    "npm-real": NpmReal,
    "yarn1": Yarn1,
    "yarn1-real": Yarn1Real,
    "yarn2": Yarn2,
    "yarn2-real": Yarn2Real,
    "cargo": Cargo.init,
    "cargo-real": CargoReal
]

let ALL_LOCAL_MANAGER_NAMES: [String] = ALL_MANAGERS.keys.filter { !$0.hasSuffix("-real") }
let ALL_REAL_MANAGER_NAMES: [String] = ALL_MANAGERS.keys.filter { $0.hasSuffix("-real") }


@discardableResult
func runProgramWithPackageManagers(managerNames: [String], program: EcosystemProgram, funcName: String = #function) -> [ExecutionResult<Int> : Set<String>] {
    
    let managers = managerNames.map { ALL_MANAGERS[$0]!() }
    
    let resultGroups = managers
        .map { (program.run(underPackageManager: $0), $0.uniqueName) }
        .reduce(into: [:]) { ( groups: inout [ExecutionResult<Int> : Set<String>], result_name) in
            let (result, name) = result_name
            groups[result, default: []].insert(name)
        }


    print("Test \(funcName) results:")
    for (result, group) in resultGroups {
        print(group)
        print(result)
        print()
    }
    print("------------------------------------\n\n")

    return resultGroups
}


@discardableResult
func runProgramWithAllPackageManagers(program: EcosystemProgram, funcName: String = #function) -> [ExecutionResult<Int> : Set<String>] {
    let allPackageManagers: [String]
    if shouldRunReal() {
        allPackageManagers = ALL_LOCAL_MANAGER_NAMES + ALL_REAL_MANAGER_NAMES
    } else {
        allPackageManagers = ALL_LOCAL_MANAGER_NAMES
    }
    
    return runProgramWithPackageManagers(managerNames: allPackageManagers, program: program, funcName: funcName)
}

@discardableResult
func runProgramWithPackageManagers(managerNames: [String], programName: String, funcName: String = #function) -> [ExecutionResult<Int> : Set<String>] {
    runProgramWithPackageManagers(managerNames: managerNames, program: ALL_PROGRAMS[programName]!, funcName: funcName)
}

@discardableResult
func runProgramWithAllPackageManagers(programName: String, funcName: String = #function) -> [ExecutionResult<Int> : Set<String>] {
    runProgramWithAllPackageManagers(program: ALL_PROGRAMS[programName]!, funcName: funcName)
}


func shouldRunReal() -> Bool {
    guard let enableStr = ProcessInfo.processInfo.environment["ENABLE_REAL_REGISTRIES"] else {
        return false
    }
    return enableStr.lowercased() == "true" || enableStr.lowercased() == "yes" || enableStr.lowercased() == "1"
}
