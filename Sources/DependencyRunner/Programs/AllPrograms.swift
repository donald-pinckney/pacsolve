import Foundation

let ALL_PROGRAMS: [String : EcosystemProgram] = [
    "ManagersWork": managersWork,
    
]


@discardableResult
func runProgramWithPackageManagers(managerInits: [() -> PackageManager], program: EcosystemProgram, funcName: String = #function) -> [[SolveResult] : Set<String>] {
    
    let managers = managerInits.map { $0() }
    
    let resultGroups = managers
        .map { (program.run(underPackageManager: $0), $0.uniqueName) }
        .reduce(into: [:]) { ( groups: inout [[SolveResult] : Set<String>], result_name) in
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
func runProgramWithAllPackageManagers(program: EcosystemProgram, funcName: String = #function) -> [[SolveResult] : Set<String>] {
    let allLocalPackageManagers: [() -> PackageManager] = [Pip, Npm, Yarn1, Yarn2, Cargo.init]
    let allRealPackageManagers: [() -> PackageManager] = [PipReal, NpmReal, Yarn1Real, Yarn2Real, CargoReal]
    
    let allPackageManagers: [() -> PackageManager]
    if shouldRunReal() {
        allPackageManagers = allLocalPackageManagers + allRealPackageManagers
    } else {
        allPackageManagers = allLocalPackageManagers
    }
    
    return runProgramWithPackageManagers(managerInits: allPackageManagers, program: program, funcName: funcName)
}

@discardableResult
func runProgramWithPackageManagers(managerInits: [() -> PackageManager], programName: String, funcName: String = #function) -> [[SolveResult] : Set<String>] {
    runProgramWithPackageManagers(managerInits: managerInits, program: ALL_PROGRAMS[programName]!, funcName: funcName)
}

@discardableResult
func runProgramWithAllPackageManagers(programName: String, funcName: String = #function) -> [[SolveResult] : Set<String>] {
    runProgramWithAllPackageManagers(program: ALL_PROGRAMS[programName]!, funcName: funcName)
}

func shouldRunReal() -> Bool {
    guard let enableStr = ProcessInfo.processInfo.environment["ENABLE_REAL_REGISTRIES"] else {
        return false
    }
    return enableStr.lowercased() == "true" || enableStr.lowercased() == "yes" || enableStr.lowercased() == "1"
}
