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

extension PackageManager {
    func solve(package: Package, version: Version) -> SolveResult {
        defer {
            cleanup()
        }
        
        let directory = generatedDirectoryFor(package: package, version: version)
        
        logDebug("Solving dependencies...\n")
        do {
            let output = try shellOut(to: solveCommand(package: package, version: version), at: directory)
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
    
    
    func parseIntoTreeNodes(lines: Array<Substring>.SubSequence, depth: Int) -> ([SolutionTree], Array<Substring>.SubSequence)  {
        var nodes: [SolutionTree] = []
        var linesMut = lines
        
        while true {
        
            guard let head = linesMut.first else {
                break
            }
            
            let (headDepth, package, headVersion) = parseSingleTreePackageLine(line: head)
            
            if headDepth < depth {
                break
            }
            assert(headDepth == depth)
            
            let (innerNodes, newLines) = parseIntoTreeNodes(lines: linesMut.dropFirst(), depth: depth + 1)
            linesMut = newLines
            
            nodes.append(SolutionTree(package: package, version: headVersion, children: innerNodes))
        }
        
        return (nodes, linesMut)
    }
    
    func parseIntoNonempyTree(lines: [Substring]) -> SolutionTree {
        precondition(lines.count >= 1)
        
        let (headDepth, package, version) = parseSingleTreePackageLine(line: lines[0])
        assert(headDepth == 0)
        
        let (children, newLines) = parseIntoTreeNodes(lines: lines.dropFirst(), depth: 1)
        assert(newLines.count == 0)
        
        return SolutionTree(package: package, version: version, children: children)
    }
}
