
enum SolutionGraphVertex<D>: Equatable, Hashable where D: Hashable {
    case resolvedPackage(package: Package, version: Version, data: D)
    case rootContext
    
    func mapData<R>(_ f: (D) -> R) -> SolutionGraphVertex<R> {
        switch self {
        case let .resolvedPackage(package: pkg, version: v, data: d):
            return .resolvedPackage(package: pkg, version: v, data: f(d))
        case .rootContext:
            return .rootContext
        }
    }
}

extension SolutionGraphVertex: Codable where D: Codable {
    enum CodingKeys: CodingKey {
        case resolved_package_vertex
        case root_context_vertex
    }
    
    enum InnerKeys: CodingKey {
        case package
        case version
        case data
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .resolvedPackage(package: p, version: v, data: d):
            var args = container.nestedContainer(keyedBy: InnerKeys.self, forKey: .resolved_package_vertex)
            try args.encode(p, forKey: .package)
            try args.encode(v, forKey: .version)
            try args.encode(d, forKey: .data)
        case .rootContext:
            try container.encodeNil(forKey: .root_context_vertex)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = container.allKeys
        if keys.count != 1 {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected exactly 1 key when decoding SolutionGraphVertex"))
        }
        
        let k = keys[0]
        switch k {
        case .resolved_package_vertex:
            let inner = try container.nestedContainer(keyedBy: InnerKeys.self, forKey: k)
            try self = .resolvedPackage(package: inner.decode(Package.self, forKey: .package),
                                        version: inner.decode(Version.self, forKey: .version),
                                        data: inner.decode(D.self, forKey: .data))
        case .root_context_vertex:
            if !(try container.decodeNil(forKey: k)) {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [k], debugDescription: "Expected null value to be encoded"))
            }
            self = .rootContext
        }
    }
}

struct SolutionGraph<D>: Equatable, Hashable where D: Hashable {
    var vertices: [SolutionGraphVertex<D>] = [.rootContext]
    var contextVertex: Int = 0
    var adjacencyLists: [Int : Set<Int>] = [0 : []]
    
    mutating func addEdge(from: Int, to: Int) {
        adjacencyLists[from]!.insert(to)
    }
    
    mutating func addContextEdge(to: Int) {
        self.addEdge(from: contextVertex, to: to)
    }
    
    mutating func addVertex(_ v: SolutionGraphVertex<D>) -> Int {
        let idx = vertices.count
        assert(adjacencyLists[idx] == nil)
        vertices.append(v)
        adjacencyLists[idx] = []
        return idx
    }
    
    func mapVertices<R>(_ f: (SolutionGraphVertex<D>) -> SolutionGraphVertex<R>) -> SolutionGraph<R> {
        return SolutionGraph<R>(vertices: self.vertices.map(f), contextVertex: self.contextVertex, adjacencyLists: self.adjacencyLists)
    }
}

extension SolutionGraph: Codable where D: Codable {}

extension SolutionGraph where D == AnyHashable {
    init<TD>(fromTree tempTree: SolutionTree<TD>) {
        
        let t = tempTree.mapData { _ in Unit() as AnyHashable }
        
        self = SolutionGraph()
        
        var subtreeToVertexMap: [ResolvedPackage<D> : Int] = [:]
        
        let immediateDependencyVertices = t.traversePostorderExceptRoot { (pkg, childVertices: [Int]) in
            let myVertex: Int

            if let maybeMyVertex = subtreeToVertexMap[pkg] {
                myVertex = maybeMyVertex
            } else {
                myVertex = self.addVertex(.resolvedPackage(package: pkg.package, version: pkg.version, data: pkg.data))
                subtreeToVertexMap[pkg] = myVertex
            }
            
            childVertices.forEach {
                self.addEdge(from: myVertex, to: $0)
            }
            
            return myVertex
        }
        
        immediateDependencyVertices.forEach {
            self.addContextEdge(to: $0)
        }
    }
}

extension SolutionGraph: CustomStringConvertible {
    var description: String {
        "\ngraph here\n"
    }
}
