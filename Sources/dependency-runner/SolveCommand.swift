import ShellOut

enum SolveResult : CustomStringConvertible, Equatable, Hashable {
    var description: String {
        get {
            switch self {
            case .solveOk(let str): return "\(str)\n"
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
    
    let packageManager: PackageManager
    
    var postProcess: (String) -> String = { $0 }
    
//    let shutdownCommand: String?
    
    func solve() -> SolveResult {
        defer {
            packageManager.cleanup()
        }
        
        logDebug("Solving dependencies...\n")
        do {
            let output = try shellOut(to: command, at: directory)
            let marker = "TREE DUMP:\n"
            if let markerRange = output.range(of: marker) {
                let output = String(output[markerRange.upperBound..<output.endIndex])
                return .solveOk(self.postProcess(output))
            } else {
                return .solveError("")
            }
        } catch {
            return .solveError("\(error)")
        }
    }
}
