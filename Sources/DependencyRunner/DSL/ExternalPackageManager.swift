import Foundation
import ShellOut

struct Unit: Hashable, Codable {}

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
    
    func run(program: EcosystemProgram) -> Result<[SolutionTree<AnyHashable>], ExecutionError> {
                
        do {
            let enc = JSONEncoder()
            let jsonIn = try enc.encode(program)
            
            let tempFileIn = try self.dirManager.newTempFile(ext: "in.json", contents: jsonIn)
            let tempFileOut = try self.dirManager.newTempFile(ext: "out.json", contents: nil)

            try shellOut(to: baseCommand + ["--input-json", tempFileIn.path, "--output-json", tempFileOut.path])
            
            let jsonOut = try Data(contentsOf: tempFileOut)
            
            let dec = JSONDecoder()
            let result = try dec.decode(Result<[SolutionTree<Unit>], ExecutionError>.self, from: jsonOut)
            
            return result.map { $0.map { $0.mapData { $0 as AnyHashable} } }
        } catch {
            return .failure(ExecutionError(message: "Communication error: \(error)"))
        }
    }
}


