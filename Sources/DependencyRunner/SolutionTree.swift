
struct SolutionTreePackage: Equatable, Hashable {
    let name: String
    let version: Version
    let children: [SolutionTreePackage]
    
    func description(depth: Int, lines: inout [String]) {
        let indent = String(repeating: "  ", count: depth)
        lines.append("\(indent)\(name) v\(version.semverName)")
        for c in children {
            c.description(depth: depth + 1, lines: &lines)
        }
    }
}

public struct SolutionTreeMain: CustomStringConvertible, Equatable, Hashable {
    let name: String
    let children: [SolutionTreePackage]
    
    public var description: String {
        get {
            var lines: [String] = ["__main_pkg__"]
            
            for c in children {
                c.description(depth: 1, lines: &lines)
            }
            
            return lines.joined(separator: "\n")
        }
    }
}
