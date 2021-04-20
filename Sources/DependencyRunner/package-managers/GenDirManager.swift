import Foundation

class GenDirManager {
    static var freeNames: [String : Int] = [:]
    
    let genName: String
    var genBasePath: String { "generated/\(genName)/" }
    
    let fileManager = FileManager()
    var createdUniqueDirs: Set<String> = Set()
    var freeContextName = 0
    
    init(baseName: String) {
        let n = GenDirManager.freeNames[baseName, default: 0]
        GenDirManager.freeNames[baseName] = n + 1
        genName = "\(baseName)-\(n)"
        
        Utils.cdToProjectRoot()

        let _ = try? fileManager.removeItem(atPath: genBasePath)
    }
    
    func generateUniqueSourceDirectory(forPackage: Package, version: Version) -> String {
        let path = "\(genBasePath)sources/\(forPackage)/\(version)/"
        assert(!fileManager.fileExists(atPath: path))
        
        try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
    
    func getUniqueDirectory(name: String) -> String {
        let path = "\(genBasePath)\(name)/"
        if !createdUniqueDirs.contains(name) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            createdUniqueDirs.insert(name)
        }
        return path
    }
    
    func getRegistryDirectory() -> String {
        return getUniqueDirectory(name: "registry")
    }
    
    func getConfigsDirectory() -> String {
        return getUniqueDirectory(name: "configs")
    }
    
    func newContextDirectory() -> String {
        let contextDirPath = "\(genBasePath)contexts/\(freeContextName)/"
        freeContextName += 1
        
        try! fileManager.createDirectory(atPath: contextDirPath, withIntermediateDirectories: true)
        
        return contextDirPath
    }
}
