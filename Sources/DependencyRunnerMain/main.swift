import ArgumentParser
@testable import DependencyRunner

struct RunProgram: ParsableCommand {
    @Argument() var programName: String
    @Argument() var packageManagerNames: [String]
    @Flag(wrappedValue: false) var inlineImage: Bool
    
    func run() {
        if packageManagerNames.count == 1 && packageManagerNames[0].lowercased() == "all" {
            runProgramWithAllPackageManagers(programName: programName, iTerm2: inlineImage)
        } else {
            runProgramWithPackageManagers(managerNames: packageManagerNames, programName: programName, iTerm2: inlineImage)
        }
    }
}

RunProgram.main()
