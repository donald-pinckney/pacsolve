struct SolutionTree: CustomStringConvertible, Equatable, Hashable {
    let package: Package
    let version: Version
    let children: [SolutionTree]
    
    func description(depth: Int, lines: inout [String]) {
        let indent = String(repeating: "  ", count: depth)
        lines.append("\(indent)\(package) v\(version.semverName)")
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
