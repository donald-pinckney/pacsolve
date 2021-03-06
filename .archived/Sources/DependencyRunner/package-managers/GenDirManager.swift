import Foundation

class GenDirManager {
    static var freeNames: [String : Int] = [:]
    
    let genName: String
    let genBasePath: String
    let genBaseURL: URL
    
    let wd: String
    let wdURL: URL
    
    let fileManager = FileManager()
    var createdUniqueDirs: Set<String> = Set()
    var createdSourceDirs: [Package : [Version : String]] = [:]
    var freeContextName = 0
    var freeTempName = 0
    var freeSourceName = 0

    
    init(baseName: String) {
        let n = GenDirManager.freeNames[baseName, default: 0]
        GenDirManager.freeNames[baseName] = n + 1
        genName = "\(baseName)-\(n)"
        genBasePath = "generated/\(genName)/"
        
        Utils.cdToProjectRoot()
        wd = fileManager.currentDirectoryPath
        wdURL = URL(fileURLWithPath: wd, isDirectory: true)
        
        genBaseURL = URL(fileURLWithPath: genBasePath, isDirectory: true, relativeTo: wdURL)

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
    
    func newTempFile(ext: String, contents md: Data?) throws -> URL {
        let tempURL = genBaseURL.appendingPathComponent("\(freeTempName).\(ext)", isDirectory: false)
        freeTempName += 1
        
        try fileManager.createDirectory(atPath: genBasePath, withIntermediateDirectories: true)
        
        if let d = md {
            try d.write(to: tempURL)
        }

        return tempURL
    }
    
    func newSourceDirectory(package: Package, version: Version) -> String {
        if let dir = self.createdSourceDirs[package]?[version] {
            return dir
        } else {
            let sourceDirPath = "\(genBasePath)sources/\(freeSourceName)/"
            freeSourceName += 1
            try! fileManager.createDirectory(atPath: sourceDirPath, withIntermediateDirectories: true)
            self.createdSourceDirs[package, default: [:]][version] = sourceDirPath
            return sourceDirPath
        }
    }
}
