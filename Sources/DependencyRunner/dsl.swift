public struct Version : Equatable, Hashable, ExpressibleByStringLiteral {
    let major : Int
    let minor : Int
    let bug : Int
    
    public init (major: Int, minor: Int, bug: Int) {
        self.major = major
        self.minor = minor
        self.bug = bug
    }
    
    public init (stringLiteral value: String) {
        let semverTerms: [Int] = value.split(separator: ".").map { Int.init($0)! }
        self.init(major: semverTerms[0], minor: semverTerms[1], bug: semverTerms[2])
    }
    
    var directoryName : String {
        get {
            semverName
        }
    }
    
    var semverName : String {
        get {
            "\(major).\(minor).\(bug)"
        }
    }
    
    static func <(lhs: Version, rhs: Version) -> Bool {
        (lhs.major, lhs.minor, lhs.bug) < (rhs.major, rhs.minor, rhs.bug)
    }
}

public enum VersionSpecifier {
    case exactly(Version)
    case geq(Version)
    case gt(Version)
    case leq(Version)
    case lt(Version)
    case caret(Version)
    case tilde(Version)
    case any
}

public func ==(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.exactly(rhs)
}

public func >=(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.geq(rhs)
}

public func >(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.gt(rhs)
}

public func <=(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.leq(rhs)
}

public func <(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.lt(rhs)
}

public func ^(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.caret(rhs)
}




public struct Package : Equatable, Hashable {
    let name : String
    let versions : [Version]
    
    public init(name: String, versions: [Version]) {
        self.name = name
        self.versions = versions
    }
    
    public func version(_ v: Version) -> VersionedPackage {
        VersionedPackage(package: self, version: v)
    }
    
    public func exactly(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.exactly(v))
    }
    
    public func geq(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.geq(v))
    }
    
    public func gt(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.gt(v))
    }
    
    public func leq(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.leq(v))
    }
    
    public func lt(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.lt(v))
    }
    
    public func caret(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.caret(v))
    }
    
    public func tilde(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.tilde(v))
    }
    
    public func any() -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.any)
    }
}

public struct MainPackage {
    public init() {
        
    }
    
    public func dependsOn(_ deps: (Package, VersionSpecifier)...) -> Dependencies {
        Dependencies(main_deps: deps, non_main_deps: [:])
    }
}



public struct VersionedPackage {
    let package: Package
    let version: Version
    
    public func dependsOn(_ deps: (Package, VersionSpecifier)...) -> Dependencies {
        Dependencies(main_deps: [], non_main_deps: [package : [version : deps]])
    }
}

public struct Dependencies {
    let main_deps : [(Package, VersionSpecifier)]
    let non_main_deps: [Package : [Version : [(Package, VersionSpecifier)]]]
    
    func and(_ deps: Dependencies) -> Dependencies {
        let merged = non_main_deps.merging(deps.non_main_deps) { (deps1, deps2) -> [Version : [(Package, VersionSpecifier)]] in
            deps1.merging(deps2, uniquingKeysWith: +)
        }
        return Dependencies(
            main_deps: main_deps + deps.main_deps,
            non_main_deps: merged)
    }
    
    static func &&(lhs: Dependencies, rhs: Dependencies) -> Dependencies {
        lhs.and(rhs)
    }
    
    static func empty() -> Dependencies {
        Dependencies(main_deps: [], non_main_deps: [:])
    }
    
    public func solve(usingPackageManagers managers: [PackageManager]) -> [SolveResult : Set<String>] {
        let outputAndName = managers.map { manager -> (SolveResult, String) in
//            print("Running \(manager.name)")
            return (manager.generate(dependencies: self).solve(), manager.name)
        }
        
        var resultGroups: [SolveResult : Set<String>] = [:]
        
        for (output, name) in outputAndName {
            resultGroups[output, default: []].insert(name)
        }
        
        return resultGroups
    }
    
    func solveUsingAllPackageManagers() -> [SolveResult : Set<String>] {
        return solve(usingPackageManagers: allPackageManagers())
    }
}

public func dependencies(_ all_deps : Dependencies...) -> Dependencies {
    all_deps.reduce(.empty(), &&)
}

public func allPackageManagers() -> [PackageManager] {
    [Pip(), Npm(), Yarn1(), Yarn2(), Cargo()]
}
