import ShellOut

public enum SolveResult : CustomStringConvertible, Hashable, Equatable {
    public var description: String {
        get {
            switch self {
            case .solveOk(let str): return "\(str)\n"
            case .solveError(let err): return "ERROR SOLVING DEPENDENCIES. ERROR MESSAGE: \n\(err)"
            }
        }
    }
    
    case solveOk(SolutionTreeMain)
    case solveError(String)
}

public struct SolveCommand {
    let directory: String
    let command: String
    
    let packageManager: PackageManager
            
    func solve() -> SolveResult {
        defer {
            packageManager.cleanup()
        }
        
        logDebug("Solving dependencies...\n")
        do {
            let output = try shellOut(to: command, at: directory)
            let marker = "TREE DUMP:\n"
            if let markerRange = output.range(of: marker) {
                let output = output[markerRange.upperBound..<output.endIndex]
                let lines = output.split(separator: "\n")
                let tree = parseIntoNonempyTree(lines: lines)
                return .solveOk(tree)
            } else {
                return .solveError("Invalid tree dump: \(output)")
            }
        } catch {
            return .solveError("\(error)")
        }
    }
    
    
    func parseIntoTreeNodes(lines: Array<Substring>.SubSequence, depth: Int) -> ([SolutionTreePackage], Array<Substring>.SubSequence)  {
        var nodes: [SolutionTreePackage] = []
        var linesMut = lines
        
        while true {
        
            guard let head = linesMut.first else {
                break
            }
            
            let (headDepth, headName, headVersion) = packageManager.parseSingleTreePackageLine(line: head)
            
            if headDepth < depth {
                break
            }
            assert(headDepth == depth)
            
            let (innerNodes, newLines) = parseIntoTreeNodes(lines: linesMut.dropFirst(), depth: depth + 1)
            linesMut = newLines
            
            nodes.append(SolutionTreePackage(name: headName, version: headVersion, children: innerNodes))
        }
        
        return (nodes, linesMut)
    }
    
    func parseIntoNonempyTree(lines: [Substring]) -> SolutionTreeMain {
        precondition(lines.count >= 1)
        
        let (headDepth, headName) = packageManager.parseSingleTreeMainLine(line: lines[0])
        assert(headDepth == 0)
        
        let (children, newLines) = parseIntoTreeNodes(lines: lines.dropFirst(), depth: 1)
        assert(newLines.count == 0)
        
        return SolutionTreeMain(name: headName, children: children)
    }
}
