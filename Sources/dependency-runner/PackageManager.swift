import Files
import ShellOut

protocol PackageManager {
    var name : String { get }
    func generate(inSourceDir: String, dependencies: Dependencies) -> SolveCommand
    func cleanup()
    
    func parseSingleTreeMainLine(line: Substring) -> (Int, String)
    
    func parseSingleTreePackageLine(line: Substring) -> (Int, String, Version)
}


extension PackageManager {
    func generate(dependencies: Dependencies) -> SolveCommand {
        changeToProjectRoot()
        
        logDebug("Generating dependencies...")
        
        if let genFolder = try? Folder(path: self.genPathDir) {
            try! genFolder.delete()
        }
        mkdir_p(path: self.genSourcesPathDir)
        
        return generate(inSourceDir: self.genSourcesPathDir, dependencies: dependencies)
    }
    
    var mainTemplateDir: Folder {
        get {
            try! Folder(path: "Templates/\(self.name)/main/")
        }
    }
    
    var packageTemplateDir: Folder {
        get {
            try! Folder(path: "Templates/\(self.name)/package/")
        }
    }
    
    var genPathDir: String {
        get {
            "generated/\(self.name)/"
        }
    }
    
    var genSourcesPathDir: String {
        get {
            "generated/\(self.name)/sources/"
        }
    }
}

extension PackageManager {
    @discardableResult func run(script: String, arguments: [String]) -> String {
        return try! shellOut(to: "Scripts/\(self.name)/\(script)", arguments: arguments)
    }
}

