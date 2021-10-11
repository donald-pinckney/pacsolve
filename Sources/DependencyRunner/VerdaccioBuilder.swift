import Foundation
import SQLite


struct DependencyRow {
    let src_package_id: Int64
    let version_id: Int64
    let datetime: Date
    let dst_package_ref: PackageRef
    let constraint: String
    let depType: DependencyType
}





enum PackageRef {
    case known(Int64)
    case unknown(String)
}

struct Tables {
    let package = Table("package")
    let version = Table("version")
    let dependency = Table("dependency")
    let version_dependencies = Table("version_dependencies")
}

struct Columns {
    let id = Expression<Int64>("id")
    let name = Expression<String>("name")
    let created = Expression<String>("created")
    let package_id_notnull = Expression<Int64>("package_id")
    let package_id_nullable = Expression<Int64?>("package_id")
    let package_raw_nullable = Expression<String?>("package_raw")
    let spec_raw = Expression<String?>("spec_raw")
    let type = Expression<Int64>("type")
    let version_id = Expression<Int64>("version_id")
    let dependency_id = Expression<Int64>("dependency_id")
    let dependency_index = Expression<Int64>("dependency_index")
    
    let major = Expression<Int64>("major")
    let minor = Expression<Int64>("minor")
    let bug = Expression<Int64>("bug")
    let prerelease = Expression<String?>("prerelease")
    let build = Expression<String?>("build")
}

public struct VerdaccioBuilder {
    let db: Connection
    let initialSQL: String
    
    var packageLookupMemo: [Int64 : Package] = [:]
    var versionLookupMemo: [Int64 : Version] = [:]
    
    let tables: Tables = Tables()
    let columns: Columns = Columns()
    
    

    public init(dbPath: String, initialSQL: String) {
        self.db = try! Connection(dbPath, readonly: true)
        self.initialSQL = initialSQL
    }
    
    
    public mutating func run() throws {
        // 0. Initialize `seenPackageIds` as an empty set, `bfsQueue` as empty array
        var seenPackageIds: Set<Int64> = []
        var bfsQueue: [Int64] = []
        
        // 1. Initial SQL query to SELECT package ID's. Add all to `bfsQueue`.
        let initialPkgIds = initialQuery()
        bfsQueue.append(contentsOf: initialPkgIds)
        seenPackageIds.formUnion(initialPkgIds)
                
        var depsMap: [Int64 : [Int64 : (datetime: Date, deps: [(PackageRef, String, DependencyType)])]] = [:]
        
        // 2. Until `bfsQueue` is empty:
        while !bfsQueue.isEmpty {
            print("Processed \(seenPackageIds.count), queue size = \(bfsQueue.count)")
            
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
                
                depsMap[r.src_package_id]![r.version_id]!.deps.append((r.dst_package_ref, r.constraint, r.depType))
            }
            
            // 2d. Add all previously unseen dst packages to the bfs queue
            for r in newRows {
                guard case let .known(dstId) = r.dst_package_ref else { continue }
                
                if !seenPackageIds.contains(dstId) {
                    seenPackageIds.insert(dstId)
                    bfsQueue.append(dstId)
                }
            }
        }
        
        // 3.  Post-process into an EcosystemProgram, sorted by Date
        var ops_dated: [(op: EcosystemOp, datetime: Date)] = []
        for (key: pkgId, value: versions) in depsMap {
            let srcPkg = lookupPackageName(packageId: pkgId)
            for (key: versionId, value: (datetime: d, deps: dependencies)) in versions {
                let srcVersion = lookupVersion(versionId: versionId)
                let deps = dependencies.compactMap { (dep: (PackageRef, String, DependencyType)) -> DependencyExpr? in
                    switch dep.0 {
                    case let .known(dstPkgId):
                        return DependencyExpr(packageToDependOn: lookupPackageName(packageId: dstPkgId), constraint: .other(dep.1), depType: dep.2)
                    case let .unknown(dstPkgName):
//                        return nil
//                        print("Warning: including unknown dependency: \(dstPkgName)")
                        return DependencyExpr(packageToDependOn: dstPkgName, constraint: .other(dep.1), depType: dep.2)
                    }
                }
                
                ops_dated.append((op: .publish(package: srcPkg, version: srcVersion, dependencies: deps), datetime: d))
            }
        }
        
        ops_dated.sort() { $0.datetime < $1.datetime }
        
//        print(ops_dated)
        print(ops_dated.count)
        
        return
        
        
        let prog = EcosystemProgram(declaredContexts: [], ops: ops_dated.map { $0.op })
        
        // 4. Run the ecosystem program
        runProgramWithPackageManagers(managerNames: ["npm"], program: prog)
    }
    
    
    func initialQuery() -> [Int64] {
        return try! db.prepare(self.initialSQL).map { $0[0]! as! Int64 }
    }
    
    
    func dependenciesQuery(packageId srcPkgId: Int64) -> [DependencyRow] {
        // Join package & version & dependency info, to get rows with package_id = `srcPkgId`
        // NOTE: We MUST sort by dependency index before retuning
        
//        SELECT version.package_id AS package_id,
//               version.id AS version_id,
//               version.created AS version_created,
//               dependency.package_id AS dependency_known_dst,
//               dependency.package_raw AS dependency_unknown_dst,
//               dependency.spec_raw AS dependency_spec_raw,
//               version_dependencies.type AS dependency_type
//          FROM version
//               JOIN
//               version_dependencies ON version.package_id = 1540625 AND
//                                       version_dependencies.version_id = version.id
//               JOIN
//               dependency ON dependency.id = version_dependencies.dependency_id
//         ORDER BY dependency_index ASC;
                
        let query = tables.version
            .join(tables.version_dependencies,
                  on: tables.version[columns.package_id_notnull] == srcPkgId && tables.version_dependencies[columns.version_id] == tables.version[columns.id])
            .join(tables.dependency,
                  on: tables.dependency[columns.id] == tables.version_dependencies[columns.dependency_id])
            .order(columns.dependency_index)
            .select(tables.version[columns.package_id_notnull],
                    tables.version[columns.id],
                    tables.version[columns.created],
                    tables.dependency[columns.package_id_nullable],
                    tables.dependency[columns.package_raw_nullable],
                    tables.dependency[columns.spec_raw],
                    tables.version_dependencies[columns.type])
            
        var loadedRows: [DependencyRow] = []
        for row in try! db.prepare(query) {
            let package_id = row[tables.version[columns.package_id_notnull]]
            let version_id = row[tables.version[columns.id]]
            let version_created_str = row[tables.version[columns.created]]
            let dependency_known_dst = row[tables.dependency[columns.package_id_nullable]]
            let dependency_unknown_dst = row[tables.dependency[columns.package_raw_nullable]]
            let spec_raw = row[tables.dependency[columns.spec_raw]]
            let type = DependencyType(rawValue: row[tables.version_dependencies[columns.type]])!
            
            
            let formatter1 = DateFormatter()
            formatter1.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZZZZZ"
            formatter1.locale = Locale(identifier: "en_US_POSIX")
            formatter1.timeZone = TimeZone(secondsFromGMT: 0)
            
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
            formatter2.locale = Locale(identifier: "en_US_POSIX")
            formatter2.timeZone = TimeZone(secondsFromGMT: 0)
            
            let version_created = formatter1.date(from: version_created_str) ?? formatter2.date(from: version_created_str)!
            
            
            let dst_ref: PackageRef
            if let known_dst = dependency_known_dst {
                dst_ref = .known(known_dst)
            } else {
                dst_ref = .unknown(dependency_unknown_dst!)
            }
            
            loadedRows.append(DependencyRow(
                                src_package_id: package_id,
                                version_id: version_id,
                                datetime: version_created,
                                dst_package_ref: dst_ref,
                                constraint: spec_raw ?? "*",
                                depType: type))
        }
        
        return loadedRows
    }
    
    func queryPackageName(packageId: Int64) -> Package {
        let row = try! db.pluck(
            tables.package.filter(columns.id == packageId)
                .select(columns.name))!
        return row[columns.name]
    }
    
    func queryVersion(versionId: Int64) -> Version {
        let row = try! db.pluck(
            tables.version.filter(columns.id == versionId)
                .select(columns.major, columns.minor, columns.bug, columns.prerelease, columns.build))!
        return Version(
            major: Int(row[columns.major]),
            minor: Int(row[columns.minor]),
            bug: Int(row[columns.bug]),
            prerelease: row[columns.prerelease],
            build: row[columns.build])
    }
    
    mutating func lookupPackageName(packageId: Int64) -> Package {
        if let p = packageLookupMemo[packageId] {
            return p
        }

        let p = queryPackageName(packageId: packageId)
        packageLookupMemo[packageId] = p
        return p
    }
    
    
    
    mutating func lookupVersion(versionId: Int64) -> Version {
        if let v = versionLookupMemo[versionId] {
            return v
        }

        let v = queryVersion(versionId: versionId)
        versionLookupMemo[versionId] = v
        return v
    }
}
