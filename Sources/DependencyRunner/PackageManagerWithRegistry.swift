import Files

//protocol PackageManagerWithRegistry: PackageManager {
//    associatedtype PublishData
//    
//    func initRegistry()
//    
//    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [DependencyExpr]) -> [String : String]
//    
//    func publish(package: Package, version: Version, pkgDir: String, dependencies: [DependencyExpr]) -> PublishData
//    
//    func finalizeRegistry(publishingData: [Package : [Version : PublishData]])
//}
//
//extension PackageManagerWithRegistry {
//    func generate(inSourceDir: String, ecosystem: Ecosystem) {
//        initRegistry()
//        
//        for node in ecosystem {
//            generate(inDir: inSourceDir, package: node.package, version: node.version, dependencies: node.dependencies)
//        }
//
//                
//        var pkgVersionPublishDataMap: [Package : [Version : PublishData]] = [:]
//                
//        for node in ecosystem {
//            let pkgDir = "\(inSourceDir)\(node.package)/\(node.version.directoryName)/"
//            let pubData = publish(package: node.package, version: node.version, pkgDir: pkgDir, dependencies: node.dependencies)
//            pkgVersionPublishDataMap[node.package, default: [:]][node.version] = pubData
//        }
//        
//        finalizeRegistry(publishingData: pkgVersionPublishDataMap)
//    }
//    
//    
//    func rewriteTemplate(file: File, substitutions: [String : String]) {
//        var contents = try! file.readAsString()
//        for (templateVar, sub) in substitutions {
//            contents = contents.replacingOccurrences(of: templateVar, with: sub)
//        }
//        try! file.write(contents)
//    }
//    
//    func rewriteTemplate(folder: Folder, substitutions: [String : String]) {
//        guard let sub = substitutions[folder.name] else {
//            return
//        }
//        
//        try! folder.rename(to: sub)
//    }
//    
//    func generate(inDir: String, package: Package, version: Version, dependencies: [DependencyExpr]) {
//        let destDir = "\(inDir)\(package)/\(version.directoryName)/"
//        mkdir_p(path: destDir)
//        try! cp_contents(from: self.packageTemplateDir, to: destDir)
//        
////        print("Generating:\n\tPackage: \(destFolder.path)\n\tdependencies:\(dependencies)\n")
//
//        let substitutions = self.packageTemplateSubstitutions(package: package, version: version, dependencies: dependencies)
//        
//        let destFolder = try! Folder(path: destDir)
//        
//        for f in destFolder.files.recursive.includingHidden {
//            rewriteTemplate(file: f, substitutions: substitutions)
//        }
//        
//        for f in destFolder.subfolders.recursive {
//            rewriteTemplate(folder: f, substitutions: substitutions)
//        }
//    }
//}
