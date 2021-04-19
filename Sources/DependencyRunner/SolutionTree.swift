struct ResolvedPackage: CustomStringConvertible, Equatable, Hashable {
    let package: Package
    let version: Version
    let children: [ResolvedPackage]
    
    func description(depth: Int, lines: inout [String]) {
        let indent = String(repeating: "  ", count: depth)
        lines.append("\(indent)\(package) v\(version)")
        for c in children {
            c.description(depth: depth + 1, lines: &lines)
        }
    }
    
    var description: String {
        var lines: [String] = []
        description(depth: 0, lines: &lines)
        return lines.joined(separator: "\n")
    }
}

struct SolutionTree: CustomStringConvertible, Equatable, Hashable {
    let children: [ResolvedPackage]
    
    var description: String {
        children.map { $0.description }.joined(separator: "\n")
    }
}
