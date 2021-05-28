
struct ExecutionError: Error, Equatable, Hashable, Codable {
    let message: String
}

typealias ExecutionResult<T: Hashable> = Result<[SolutionGraph<T>], ExecutionError>


protocol PackageManager {
    associatedtype DataType: Hashable
    
    var uniqueName: String { get }
    
    func run(program: EcosystemProgram) -> Result<[SolutionGraph<DataType>], ExecutionError>
}

extension PackageManager {
    func eraseTypes() -> AnyPackageManager {
        AnyPackageManager(uniqueName: self.uniqueName, run: { prog in
            let r: Result<[SolutionGraph<AnyHashable>], ExecutionError> = self.run(program: prog).map { $0.map { $0.mapVertices { $0.mapData { $0 as AnyHashable }}}}
            return r
        })
    }
}


struct AnyPackageManager {
    let uniqueName: String
    let run: (EcosystemProgram) -> Result<[SolutionGraph<AnyHashable>], ExecutionError>
}
