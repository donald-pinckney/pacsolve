import ShellOut

enum SolveResult : CustomStringConvertible {
    var description: String {
        get {
            switch self {
            case .solveOk(let str): return "Dependency resolution tree:\n\n\(str)\n"
            case .solveError(let err): return "ERROR SOLVING DEPENDENCIES. ERROR MESSAGE: \n\(err)"
            }
        }
    }
    
    case solveOk(String)
    case solveError(String)
}

struct SolveCommand {
    let directory: String
    let command: String
    
    func solve() -> SolveResult {
        print("Solving dependencies...\n")
        do {
            let output = try shellOut(to: command, at: directory)
            return .solveOk(output)
        } catch {
            return .solveError("\(error)")
        }
    }
}
