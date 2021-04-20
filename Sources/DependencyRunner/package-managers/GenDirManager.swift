import Foundation

class GenDirManager {
    static var freeNames: [String : Int] = [:]
    
    let genName: String
    var genBasePath: String { "generated/\(genName)/" }
    let wd: String
    
    let fileManager = FileManager()
    var createdUniqueDirs: Set<String> = Set()
    var freeContextName = 0
    
    init(baseName: String) {
        let n = GenDirManager.freeNames[baseName, default: 0]
        GenDirManager.freeNames[baseName] = n + 1
        genName = "\(baseName)-\(n)"
        
        Utils.cdToProjectRoot()
        wd = fileManager.currentDirectoryPath

        let _ = try? fileManager.removeItem(atPath: genBasePath)
    }
    
    func generateUniqueSourceDirectory(forPackage: Package, version: Version) -> String {
        let path = "\(genBasePath)sources/\(forPackage)/\(version)/"
        assert(!fileManager.fileExists(atPath: path))
        
        try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        return path
    }
    
    func getUniqueDirectory(name: String) -> (relative: String, absolute: String) {
        let path = "\(genBasePath)\(name)/"
        if !createdUniqueDirs.contains(name) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            createdUniqueDirs.insert(name)
        }
        let absolutePath = "\(self.wd)/\(path)"
        return (relative: path, absolute: absolutePath)
    }
    
    func getRegistryDirectory() -> (relative: String, absolute: String) {
        return getUniqueDirectory(name: "registry")
    }
    
    func getConfigsDirectory() -> (relative: String, absolute: String) {
        return getUniqueDirectory(name: "configs")
    }
    
    func newContextDirectory() -> String {
        let contextDirPath = "\(genBasePath)contexts/\(freeContextName)/"
        freeContextName += 1
        
        try! fileManager.createDirectory(atPath: contextDirPath, withIntermediateDirectories: true)
        
        return contextDirPath
    }
}
