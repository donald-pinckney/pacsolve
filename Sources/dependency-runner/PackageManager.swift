import Files
import ShellOut

protocol PackageManager {
    var name : String { get }
    func generate(inSourceDir: String, dependencies: Dependencies) -> SolveCommand
}


extension PackageManager {
    func generate(dependencies: Dependencies) -> SolveCommand {
        print("Generating dependencies...")
        
        if let genSourcesFolder = try? Folder(path: self.genSourcesPathDir) {
            try! genSourcesFolder.delete()
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
    
    var genSourcesPathDir: String {
        get {
            "\(self.rootPathDir)generated/\(self.name)/sources/"
        }
    }
}

