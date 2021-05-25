
enum ExecutionError: Error, Equatable, Hashable {
    case publishError(error: PublishError)
    case yankError(error: YankError)
    case solveError(error: SolveError)
}

typealias ExecutionResult<T: Hashable> = Result<[SolutionTree<T>], ExecutionError>


protocol PackageManager {
    associatedtype DataType: Hashable
    
    var uniqueName: String { get }
    
    func run(program: EcosystemProgram) -> Result<[SolutionTree<DataType>], ExecutionError>
}

extension PackageManager {
    func eraseTypes() -> AnyPackageManager {
        AnyPackageManager(uniqueName: self.uniqueName, run: { prog in
            let r: Result<[SolutionTree<AnyHashable>], ExecutionError> = self.run(program: prog).map { $0.map { $0.mapData { $0 } } }
            return r
        })
    }
}


struct AnyPackageManager {
    let uniqueName: String
    let run: (EcosystemProgram) -> Result<[SolutionTree<AnyHashable>], ExecutionError>
}
