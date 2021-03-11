import Files
import ShellOut
import Foundation

protocol PackageManager {
    var name : String { get }
    func generate(inSourceDir: String, dependencies: Dependencies) -> SolveCommand
    func cleanup()
}


extension PackageManager {
    func generate(dependencies: Dependencies) -> SolveCommand {
        changeToProjectRoot()
        
        print("Generating dependencies...")
        
        if let genFolder = try? Folder(path: self.genPathDir) {
            try! genFolder.delete()
        }
        mkdir_p(path: self.genSourcesPathDir)
        
        return generate(inSourceDir: self.genSourcesPathDir, dependencies: dependencies)
    }
    
    var rootPathDir: String {
        get {
            "/Users/donaldpinckney/Research/packages/dependency-runner/"
        }
    }
    
    var mainTemplateDir: Folder {
        get {
            try! Folder(path: "\(self.rootPathDir)Templates/\(self.name)/main/")
        }
    }
    
    var packageTemplateDir: Folder {
        get {
            try! Folder(path: "\(self.rootPathDir)Templates/\(self.name)/package/")
        }
    }
    
    var genPathDir: String {
        get {
            "\(self.rootPathDir)generated/\(self.name)/"
        }
    }
    
    var genSourcesPathDir: String {
        get {
            "\(self.rootPathDir)generated/\(self.name)/sources/"
        }
    }
}

extension PackageManager {
    @discardableResult func run(script: String, arguments: [String]) -> String {
        return try! shellOut(to: "Scripts/\(self.name)/\(script)", arguments: arguments)
    }
}

