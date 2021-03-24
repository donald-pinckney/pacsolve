struct Version : Equatable, Hashable, ExpressibleByStringLiteral {
    let major : Int
    let minor : Int
    let bug : Int
    
    init (stringLiteral value: String) {
        let semverTerms: [Int] = value.split(separator: ".").map { Int.init($0)! }
        major = semverTerms[0]
        minor = semverTerms[1]
        bug = semverTerms[2]
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

enum VersionSpecifier {
    case exactly(Version)
    case geq(Version)
    case gt(Version)
    case leq(Version)
    case lt(Version)
    case caret(Version)
    case tilde(Version)
    case any
}

func ==(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.exactly(rhs)
}

func >=(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.geq(rhs)
}

func >(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.gt(rhs)
}

func <=(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.leq(rhs)
}

func <(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.lt(rhs)
}

func ^(lhs: Package, rhs: Version) -> (Package, VersionSpecifier) {
    lhs.caret(rhs)
}




struct Package : Equatable, Hashable {
    let name : String
    let versions : [Version]
    
    func version(_ v: Version) -> VersionedPackage {
        VersionedPackage(package: self, version: v)
    }
    
    func exactly(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.exactly(v))
    }
    
    func geq(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.geq(v))
    }
    
    func gt(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.gt(v))
    }
    
    func leq(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.leq(v))
    }
    
    func lt(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.lt(v))
    }
    
    func caret(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.caret(v))
    }
    
    func tilde(_ v: Version) -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.tilde(v))
    }
    
    func any() -> (Package, VersionSpecifier) {
        (self, VersionSpecifier.any)
    }
}

struct MainPackage {
    func dependsOn(_ deps: (Package, VersionSpecifier)...) -> Dependencies {
        Dependencies(main_deps: deps, non_main_deps: [:])
    }
}



struct VersionedPackage {
    let package: Package
    let version: Version
    
    func dependsOn(_ deps: (Package, VersionSpecifier)...) -> Dependencies {
        Dependencies(main_deps: [], non_main_deps: [package : [version : deps]])
    }
}

struct Dependencies {
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
    
    func solve(usingPackageManagers managers: [PackageManager]) -> [SolveResult : Set<String>] {
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

func dependencies(_ all_deps : Dependencies...) -> Dependencies {
    all_deps.reduce(.empty(), &&)
}

func allPackageManagers() -> [PackageManager] {
    [Pip(), Npm(), Yarn1(), Yarn2(), Cargo()]
}
