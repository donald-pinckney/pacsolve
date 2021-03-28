//import Files
import ShellOut
import Foundation

public protocol PackageManager {
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
        
        let _ = try? shellOut(to: "rm", arguments: ["-rf", self.genPathDir])
        mkdir_p(path: self.genSourcesPathDir)
        
        return generate(inSourceDir: self.genSourcesPathDir, dependencies: dependencies)
    }
    
    var mainTemplatePath: String {
        get {
            "Templates/\(self.name)/main/"
        }
    }
    
    var packageTemplateDir: String {
        get {
            "Templates/\(self.name)/package/"
        }
    }
    var packageTemplateDir_name: String {
        get {
            "package"
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
    @discardableResult
    func runNoOutput(script: String, arguments: [String]) -> String {
        try! shellOut(to: "Scripts/\(self.name)/\(script)", arguments: arguments)
    }
}

