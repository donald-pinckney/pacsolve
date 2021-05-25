struct ResolvedPackage<D>: CustomStringConvertible, Equatable, Hashable where D: Hashable {
    let package: Package
    let version: Version
    let data: D
    let children: [ResolvedPackage<D>]
    
    func description(depth: Int, lines: inout [String]) {
        let indent = String(repeating: "  ", count: depth)
        lines.append("\(indent)\(package) v\(version)  #\(data)")
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

extension ResolvedPackage {
    func mapPackageNames(_ f: (Package) -> Package) -> ResolvedPackage<D> {
        ResolvedPackage(package: f(self.package), version: self.version, data: self.data, children: self.children.map { $0.mapPackageNames(f) } )
    }
    
    func mapData<E>(_ f: (D) -> E) -> ResolvedPackage<E> {
        ResolvedPackage<E>(package: self.package, version: self.version, data: f(self.data), children: self.children.map { $0.mapData(f) })
    }
}

struct SolutionTree<D>: CustomStringConvertible, Equatable, Hashable where D: Hashable {
    let children: [ResolvedPackage<D>]
    
    var description: String {
        "\n" + children.map { $0.description }.joined(separator: "\n")
    }
    
    init(children: [ResolvedPackage<D>]) {
        self.children = children.map { $0.normalizedOrder() }.sorted(by: <)
    }
    
    func mapPackageNames(_ f: (Package) -> Package) -> SolutionTree {
        SolutionTree(children: self.children.map { $0.mapPackageNames(f) })
    }
    
    func mapData<E>(_ f: (D) -> E) -> SolutionTree<E> {
        SolutionTree<E>(children: self.children.map { $0.mapData(f) })
    }
}

extension ResolvedPackage: Codable where D: Codable {}

extension SolutionTree: Codable where D: Codable {}


struct SolveError: Error, Equatable, Hashable {
    let message: String
}
