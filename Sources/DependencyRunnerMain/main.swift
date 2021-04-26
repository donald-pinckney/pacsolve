import ArgumentParser
@testable import DependencyRunner

struct RunProgram: ParsableCommand {
    @Argument() var programName: String
    @Argument() var packageManagerNames: [String]
    
    func run() {
        if packageManagerNames.count == 1 && packageManagerNames[0].lowercased() == "all" {
            runProgramWithAllPackageManagers(programName: programName)
        } else {
            runProgramWithPackageManagers(managerNames: packageManagerNames, programName: programName)
        }
    }
}

RunProgram.main()
