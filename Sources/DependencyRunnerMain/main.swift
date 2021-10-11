import ArgumentParser
import Foundation
import DependencyRunner

//struct RunProgram: ParsableCommand {
//    @Argument() var programName: String
//    @Argument() var packageManagerNames: [String]
//    @Flag(wrappedValue: false) var inlineImage: Bool
//    
//    func run() {
//        if packageManagerNames.count == 1 && packageManagerNames[0].lowercased() == "all" {
//            runProgramWithAllPackageManagers(programName: programName, iTerm2: inlineImage)
//        } else {
//            runProgramWithPackageManagers(managerNames: packageManagerNames, programName: programName, iTerm2: inlineImage)
//        }
//    }
//}

struct VerdaccioBuilderCommand: ParsableCommand {
    @Option(name: .shortAndLong, help: "The path to the DB.")
    var dbPath: String
    
    @Option(name: .shortAndLong, help: "The SQL query for initial package ids.")
    var initialSQL: String
    
    func run() throws {
        var builder = VerdaccioBuilder(dbPath: dbPath, initialSQL: initialSQL)
        try builder.run()
    }
}



VerdaccioBuilderCommand.main()
