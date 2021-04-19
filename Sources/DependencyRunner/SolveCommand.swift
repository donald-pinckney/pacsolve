import ShellOut

//enum SolveResult {
//    
//}

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
//
//extension PackageManager {
//    func solve(package: Package, version: Version) -> SolveResult {
//        defer {
//            cleanup()
//        }
//        
//        let directory = generatedDirectoryFor(package: package, version: version)
//        
//        logDebug("Solving dependencies...\n")
//        do {
//            let output = try shellOut(to: solveCommand(package: package, version: version), at: directory)
//            let marker = "TREE DUMP:\n"
//            if let markerRange = output.range(of: marker) {
//                let output = output[markerRange.upperBound..<output.endIndex]
//                let lines = output.split(separator: "\n")
//                let tree = parseIntoNonempyTree(lines: lines)
//                return .solveOk(tree)
//            } else {
//                return .solveError("Invalid tree dump: \(output)")
//            }
//        } catch {
//            return .solveError("\(error)")
//        }
//    }
//    
//    
//    
