import Foundation
import Files

protocol TemplateManagerDelegate : AnyObject {
    func templateSubstitutionsFor(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String]
}

struct TemplateManager {
    let templateName: String
    weak var delegate: TemplateManagerDelegate? = nil
    
    private let fileManager = FileManager()
    
    func instantiateTemplate(name: String, intoDirectory: String, substitutions: [String : String]) {
        let templateDirPath = "Templates/\(templateName)/\(name)/"
        let currentDirURL = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let templateDirURL = URL(fileURLWithPath: templateDirPath, isDirectory: true, relativeTo: currentDirURL)
        
        let destRootDirURL = URL(fileURLWithPath: intoDirectory, isDirectory: true, relativeTo: currentDirURL)
        
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey, .parentDirectoryURLKey])
        let enu = fileManager.enumerator(at: templateDirURL, includingPropertiesForKeys: Array(resourceKeys))!
        
        for case let itemURL as URL in enu {
            let resourceValues = try! itemURL.resourceValues(forKeys: resourceKeys)
            let isDirectory = resourceValues.isDirectory!
            let parentURL = resourceValues.parentDirectory!
            let name = resourceValues.name!
            
            let parentComponentsRelativeToTemplateRoot = parentURL.pathComponents[templateDirURL.pathComponents.count...]
            
            let destParentURL: URL = (parentComponentsRelativeToTemplateRoot).reduce(destRootDirURL) { $0.appendingPathComponent($1, isDirectory: true)  }
            let destURL = destParentURL.appendingPathComponent(name, isDirectory: isDirectory)
            
            if isDirectory {
                // This may fail because the directories may already exist,
                // in the case of re-using a solve context
                try? fileManager.createDirectory(at: destURL, withIntermediateDirectories: false)
            } else {
                let srcURL = parentURL.appendingPathComponent(name, isDirectory: false)
                var contents = try! String(contentsOf: srcURL)
                for (templateVar, templateSub) in substitutions {
                    contents = contents.replacingOccurrences(of: templateVar, with: templateSub)
                }
                try! contents.write(to: destURL, atomically: false, encoding: .utf8)
            }
        }
    }
    
    func instantiatePackageTemplate(intoDirectory: String, package: Package, version: Version, dependencies: [DependencyExpr]) {
        let substituting = self.delegate?.templateSubstitutionsFor(package: package, version: version, dependencies: dependencies) ?? [:]
        
        instantiateTemplate(name: "package", intoDirectory: intoDirectory, substitutions: substituting)
    }
    
    func instantiateContextTemplate(intoDirectory: String, package: Package, version: Version, dependencies: [DependencyExpr]) {
        let substituting = self.delegate?.templateSubstitutionsFor(package: package, version: version, dependencies: dependencies) ?? [:]
        
        instantiateTemplate(name: "context", intoDirectory: intoDirectory, substitutions: substituting)
    }
}


