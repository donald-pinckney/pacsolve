//import Files
import ShellOut
import Foundation

protocol PackageManager {
    var uniqueName : String { get }
    var templateName : String { get }
    func generate(inSourceDir: String, ecosystem: Ecosystem)
    func generatedDirectoryFor(package: Package, version: Version) -> String
    func cleanup()
    
    func parseSingleTreePackageLine(line: Substring) -> (Int, Package, Version)
    func solveCommand(package: Package, version: Version) -> String
}


extension PackageManager {
    var templateName: String {
        uniqueName
    }
    
    func generate(ecosystem: Ecosystem) {
        changeToProjectRoot()
        
        logDebug("Generating dependencies...")
        
        let _ = try? shellOut(to: "rm", arguments: ["-rf", self.genPathDir])
        mkdir_p(path: self.genSourcesPathDir)
        
        generate(inSourceDir: self.genSourcesPathDir, ecosystem: ecosystem)
    }
    
    var packageTemplateDir: String {
        get {
            "Templates/\(self.templateName)/package/"
        }
    }
    var packageTemplateDir_name: String {
        get {
            "package"
        }
    }
    
    var genPathDir: String {
        get {
            "generated/\(self.uniqueName)/"
        }
    }
    
    var genSourcesPathDir: String {
        get {
            "generated/\(self.uniqueName)/sources/"
        }
    }
}

//extension PackageManager {
//    @discardableResult
//    func runNoOutput(script: String, arguments: [String]) -> String {
//        try! shellOut(to: "Scripts/\(self.name)/\(script)", arguments: arguments)
//    }
//}

