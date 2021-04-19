
struct SolutionTreeParser {
    private var toParse: Substring
    private var treeLinesToParse: [Substring]
    
    init(toParse: String) {
        self.toParse = toParse[toParse.startIndex..<toParse.endIndex]
        self.treeLinesToParse = []
    }
    
    mutating func parseSolutionTree() -> SolveResult {
        let marker = "TREE DUMP:\n"
        if let markerRange = toParse.range(of: marker) {
            toParse = toParse[markerRange.upperBound..<toParse.endIndex]
            treeLinesToParse = toParse.split(separator: "\n")
            let tree = parseSolutionTreeLines()
            return .solveOk(tree)
        } else {
            return .solveError("Invalid tree dump: \(toParse)")
        }
    }
    
    private mutating func parseTreeNodes(depth: Int) -> [ResolvedPackage]  {
        var nodes: [ResolvedPackage] = []

        while true {
            guard let (headDepth, package, headVersion, line) = parseSingleTreePackageLine() else {
                break
            }

            if headDepth < depth {
                treeLinesToParse.insertFirst(line)
                break
            }
            assert(headDepth == depth)

            let innerNodes = parseTreeNodes(depth: depth + 1)
            nodes.append(ResolvedPackage(package: package, version: headVersion, children: innerNodes))
        }

        return nodes
    }
    
    private mutating func parseSolutionTreeLines() -> SolutionTree {
        precondition(treeLinesToParse.count >= 1)

        let (headDepth, _, _, _) = parseSingleTreePackageLine()!
        assert(headDepth == 0)

        let children = parseTreeNodes(depth: 1)
        assert(treeLinesToParse.count == 0)

        return SolutionTree(children: children)
    }
    
    
    private mutating func parseSingleTreePackageLine() -> (Int, Package, Version, Substring)? {
        guard let line = treeLinesToParse.popFirst() else {
            return nil
        }
        
        let commaIdx = line.firstIndex(of: ",")!
        let after = line[line.index(after: commaIdx)..<line.endIndex]
        let before = line[line.startIndex..<commaIdx]
        let indentSize = Int(before)!
    
        let vIdx = after.lastIndex(of: "v")!
    
        let versionStart = after.index(after: vIdx)
        let nameEnd = after.index(before: vIdx)
    
        return (indentSize, Package(stringLiteral: String(after[after.startIndex..<nameEnd])), Version(stringLiteral: String(after[versionStart..<after.endIndex])), line)
    }
}


private extension Array {
    mutating func popFirst() -> Self.Element? {
        if self.count == 0 {
            return nil
        } else {
            return self.removeFirst()
        }
    }
    
    mutating func insertFirst(_ x: Self.Element) {
        self.insert(x, at: 0)
    }
}
