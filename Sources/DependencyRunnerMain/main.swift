import ArgumentParser
import Foundation
import SQLite
@testable import DependencyRunner

struct RunProgram: ParsableCommand {
    @Argument() var programName: String
    @Argument() var packageManagerNames: [String]
    @Flag(wrappedValue: false) var inlineImage: Bool
    
    func run() {
        if packageManagerNames.count == 1 && packageManagerNames[0].lowercased() == "all" {
            runProgramWithAllPackageManagers(programName: programName, iTerm2: inlineImage)
        } else {
            runProgramWithPackageManagers(managerNames: packageManagerNames, programName: programName, iTerm2: inlineImage)
        }
    }
}

struct DependencyRow<P, V> {
    let src_package_id: P
    let version_id: V
    let datetime: Date
    let dst_package_id: P
    let constraint: String
    let depType: DependencyType
}


struct VerdaccioBuilderCommand: ParsableCommand {
    @Option(name: .shortAndLong, help: "The path to the DB.")
    var dbPath: String
    
    @Option(name: .shortAndLong, help: "The SQL query for initial package ids.")
    var initialSQL: String
    
    func run() throws {
        print("hi")
        var builder = VerdaccioBuilder(dbPath: dbPath, initialSQL: initialSQL)
        try builder.run()
    }
}


struct VerdaccioBuilder {
    let dbPath: String
    let initialSQL: String
    
    var packageLookupMemo: [Int : Package] = [:]
    var versionLookupMemo: [Int : Version] = [:]
    
    
    mutating func run() throws {
        // 0. Initialize `seenPackageIds` as an empty set, `bfsQueue` as empty array
        var seenPackageIds: Set<Int> = []
        var bfsQueue: [Int] = []
        
        // 1. Initial SQL query to SELECT package ID's. Add all to `bfsQueue`.
        let initialPkgIds = initialQuery()
        bfsQueue.append(contentsOf: initialPkgIds)
        seenPackageIds.formUnion(initialPkgIds)
                
        var depsMap: [Int : [Int : (datetime: Date, deps: [(Int, String, DependencyType)])]] = [:]
        
        // 2. Until `bfsQueue` is empty:
        while !bfsQueue.isEmpty {
            // 2a.  Pop package ID from `bfsQueue`.
            let pkgId = bfsQueue.removeFirst()
            
            // 2b.  Query to get version / dependency info for the package ID
            let newRows = dependenciesQuery(packageId: pkgId)
            
            // 2c.  Add queried data to the map of dependencies
            for r in newRows {
                if depsMap[r.src_package_id] == nil {
                    depsMap[r.src_package_id] = [:]
                }
                
                if depsMap[r.src_package_id]![r.version_id] == nil {
                    depsMap[r.src_package_id]![r.version_id] = (datetime: r.datetime, deps: [])
                }
                
                depsMap[r.src_package_id]![r.version_id]!.deps.append((r.dst_package_id, r.constraint, r.depType))
            }
            
            // 2d. Add all previously unseen dst packages to the bfs queue
            for r in newRows {
                if !seenPackageIds.contains(r.dst_package_id) {
                    seenPackageIds.insert(r.dst_package_id)
                    bfsQueue.append(r.dst_package_id)
                }
            }
        }
        
        // 3.  Post-process into an EcosystemProgram, sorted by Date
        var ops_dated: [(op: EcosystemOp, datetime: Date)] = []
        for (key: pkgId, value: versions) in depsMap {
            let srcPkg = lookupPackageName(packageId: pkgId)
            for (key: versionId, value: (datetime: d, deps: dependencies)) in versions {
                let srcVersion = lookupVersion(versionId: versionId)
                let deps = dependencies.map {
                    DependencyExpr(packageToDependOn: lookupPackageName(packageId: $0.0), constraint: .other($0.1), depType: $0.2)
                }
                
                ops_dated.append((op: .publish(package: srcPkg, version: srcVersion, dependencies: deps), datetime: d))
            }
        }
        
        ops_dated.sort() { $0.datetime < $1.datetime }
        
        print(ops_dated)
        
        
        let prog = EcosystemProgram(declaredContexts: [], ops: ops_dated.map { $0.op })
        
        // 4. Run the ecosystem program
        runProgramWithPackageManagers(managerNames: ["npm"], program: prog)
    }
    
    
    func initialQuery() -> [Int] {
        // Run self.initialSQL
        fatalError()
    }
    
    func dependenciesQuery(packageId: Int) -> [DependencyRow<Int, Int>] {
        // Join package & version & dependency info, to get rows with package_id = `packageId`
        fatalError()
    }
    
    func queryPackageName(packageId: Int) -> Package {
        // Query to get a package name given an ID
        fatalError()
    }
    
    func queryVersion(versionId: Int) -> Version {
        // Query to get a version struct given an ID
        fatalError()
    }
    
    mutating func lookupPackageName(packageId: Int) -> Package {
        if let p = packageLookupMemo[packageId] {
            return p
        }

        let p = queryPackageName(packageId: packageId)
        packageLookupMemo[packageId] = p
        return p
    }
    
    
    
    mutating func lookupVersion(versionId: Int) -> Version {
        if let v = versionLookupMemo[versionId] {
            return v
        }

        let v = queryVersion(versionId: versionId)
        versionLookupMemo[versionId] = v
        return v
    }
}

VerdaccioBuilderCommand.main()
