import Foundation

class GenDirManager {
    static var freeNames: [String : Int] = [:]
    
    let genName: String
    var genBasePath: String { "generated/\(genName)/" }
    
    let fileManager = FileManager()
    var didMakeRegistryDir = false
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
    
    func getRegistryDirectory() -> String {
        let path = "\(genBasePath)registry/"
        if !didMakeRegistryDir {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            didMakeRegistryDir = true
        }
        return path
    }
    
    func newContextDirectory() -> String {
        let contextDirPath = "\(genBasePath)contexts/\(freeContextName)/"
        freeContextName += 1
        
        try! fileManager.createDirectory(atPath: contextDirPath, withIntermediateDirectories: true)
        
        return contextDirPath
    }
}
