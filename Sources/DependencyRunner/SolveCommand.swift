import ShellOut

enum SolveResult : CustomStringConvertible, Hashable, Equatable {
    case solveOk(SolutionTree)
    case solveError(String)
    
    var description: String {
        get {
            switch self {
            case .solveOk(let str): return "\(str)\n"
            case .solveError(let err): return "ERROR SOLVING DEPENDENCIES. ERROR MESSAGE: \n\(err)"
            }
        }
    }
}

extension SolveResult {
    func mapOk(_ f: (SolutionTree) -> SolutionTree) -> SolveResult {
        switch self {
        case .solveError(_): return self
        case .solveOk(let t): return .solveOk(f(t))
        }
    }
}
