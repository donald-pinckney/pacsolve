import Foundation
import ShellOut

struct Unit: Hashable, Codable {}

struct AnyVersionTypeResults: Codable {
    let results: [SolutionGraph<Unit>]
    let versionFormat: String
}

struct ExternalPackageManager: PackageManager {
    typealias DataType = AnyHashable
    
    let baseCommand: [String]
    let uniqueName: String
    let dirManager: GenDirManager
    
    init(name: String, baseCommand: [String]) {
        self.uniqueName = name
        self.baseCommand = baseCommand
        self.dirManager = GenDirManager(baseName: uniqueName)
    }
    
    func run(program: EcosystemProgram) -> Result<[SolutionGraph<AnyHashable>], ExecutionError> {
                
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = .prettyPrinted
            let jsonIn = try enc.encode(program)
            
            let tempFileIn = try self.dirManager.newTempFile(ext: "in.json", contents: jsonIn)
            let tempFileOut = try self.dirManager.newTempFile(ext: "out.json", contents: nil)

            let executable = baseCommand[0]
            let args = Array(baseCommand[1...]) + ["--in-json", tempFileIn.path, "--out-json", tempFileOut.path]
            print(try shellOut(to: executable, arguments: args))
            
            let jsonOut = try Data(contentsOf: tempFileOut)
            
            let dec = JSONDecoder()
            let result = try dec.decode(Result<AnyVersionTypeResults, ExecutionError>.self, from: jsonOut)
            
            return result.map { $0.results.map { $0.mapVertices { $0.mapData { $0 as AnyHashable }}}}
        } catch {
            return .failure(ExecutionError(message: "Communication error: \(error)"))
        }
    }
}


