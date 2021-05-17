
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
            return .success(tree)
        } else {
            return .failure(SolveError(message: "Invalid tree dump: \(toParse)"))
        }
    }
    
    private mutating func parseTreeNodes(depth: Int) -> [ResolvedPackage<Int>]  {
        var nodes: [ResolvedPackage<Int>] = []

        while true {
            guard let (headDepth, package, headVersion, data, line) = parseSingleTreePackageLine() else {
                break
            }

            if headDepth < depth {
                treeLinesToParse.insertFirst(line)
                break
            }
            assert(headDepth == depth)

            let innerNodes = parseTreeNodes(depth: depth + 1)
            nodes.append(ResolvedPackage(package: package, version: headVersion, data: data, children: innerNodes))
        }

        return nodes
    }
    
    private mutating func parseSolutionTreeLines() -> SolutionTree<Int> {
        precondition(treeLinesToParse.count >= 1)

        let (headDepth, _, _, _, _) = parseSingleTreePackageLine()!
        assert(headDepth == 0)

        let children = parseTreeNodes(depth: 1)
        assert(treeLinesToParse.count == 0)

        return SolutionTree(children: children)
    }
    
    
    private mutating func parseSingleTreePackageLine() -> (Int, Package, Version, Int, Substring)? {
        guard let line = treeLinesToParse.popFirst() else {
            return nil
        }
        
        let csv = line.split(separator: ",")
        let indentSize = Int(csv[0])!
        let package = Package(stringLiteral: String(csv[1]))
        let version = Version(stringLiteral: String(csv[2]))
        let data = Int(csv[3])!
        
        return (indentSize,
                package,
                version,
                data,
                line)
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
