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


protocol PackageManagerWithRegistry: PackageManager {
    func initRegistry()
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String]
    
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String]
    
    func publish(package: Package, version: Version, sourceDir: String)
    func solveCommand(forMainPath: String) -> SolveCommand
}

extension PackageManagerWithRegistry {
    func generate(inSourceDir: String, dependencies: Dependencies) -> SolveCommand {
        let pkgs = dependencies.allPackages()
        for pkg in pkgs {
            for v in pkg.versions {
                let deps = dependencies.non_main_deps[pkg]?[v] ?? []
                generate(inDir: inSourceDir, package: pkg, version: v, dependencies: deps)
            }
        }
        
        let mainPath = generateMain(inDir: inSourceDir, dependencies: dependencies.main_deps)
        
        for pkg in pkgs {
            for v in pkg.versions {
                publish(package: pkg, version: v, sourceDir: inSourceDir)
            }
        }
        
        return solveCommand(forMainPath: mainPath)
    }
    
    
    func rewriteTemplate(file: File, substitutions: [String : String]) {
        var contents = try! file.readAsString()
        for (templateVar, sub) in substitutions {
            contents = contents.replacingOccurrences(of: templateVar, with: sub)
        }
        try! file.write(contents)
    }
    
    func rewriteTemplate(folder: Folder, substitutions: [String : String]) {
        guard let sub = substitutions[folder.name] else {
            return
        }
        
        try! folder.rename(to: sub)
    }
    
    func generate(inDir: String, package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) {
        let destParentDir = "\(inDir)\(package.name)/"
        mkdir_p(path: destParentDir)
        let destParentFolder = try! Folder(path: destParentDir)
        
        try! self.packageTemplateDir.copy(to: destParentFolder)
        
        let tmpFolder = try! Folder(path: "\(destParentDir)\(self.packageTemplateDir.name)")
        try! tmpFolder.rename(to: version.directoryName)
        
        let destFolder = try! Folder(path: "\(destParentDir)\(version.directoryName)")

//        print("Generating:\n\tPackage: \(destFolder.path)\n\tdependencies:\(dependencies)\n")

        let substitutions = self.packageTemplateSubstitutions(package: package, version: version, dependencies: dependencies)
        
        
        for f in destFolder.files.recursive {
            rewriteTemplate(file: f, substitutions: substitutions)
        }
        
        for f in destFolder.subfolders.recursive {
            rewriteTemplate(folder: f, substitutions: substitutions)
        }
    }
    
    func generateMain(inDir: String, dependencies: [(Package, VersionSpecifier)]) -> String {
        let mainPkgName = "__main_pkg__"
        
        let destParentDir = inDir
        mkdir_p(path: destParentDir)
        let destParentFolder = try! Folder(path: destParentDir)
        
        try! self.mainTemplateDir.copy(to: destParentFolder)
        
        let tmpFolder = try! Folder(path: "\(destParentDir)\(self.mainTemplateDir.name)")
        try! tmpFolder.rename(to: mainPkgName)
        
        let destFolder = try! Folder(path: "\(destParentDir)\(mainPkgName)")

//        print("Generating:\n\tMain package: \(destFolder)\n\tdependencies:\(dependencies)\n")
        
        let substitutions = mainTemplateSubstitutions(dependencies: dependencies)
        for f in destFolder.files.recursive {
            rewriteTemplate(file: f, substitutions: substitutions)
        }
        
        for f in destFolder.subfolders.recursive {
            rewriteTemplate(folder: f, substitutions: substitutions)
        }
        
        return destFolder.path
    }
}


struct Pip : PackageManagerWithRegistry {
    let name = "pip"
    var genBinPathDir: String {
        get {
            "\(self.rootPathDir)generated/\(self.name)/bin/"
        }
    }
    
    func initRegistry() {
        if let genBinFolder = try? Folder(path: self.genBinPathDir) {
            try! genBinFolder.delete()
        }
        mkdir_p(path: self.genBinPathDir)
    }
    
    
    func versionSpecStr(_ vs: VersionSpecifier) -> String {
        switch vs {
        case .any:
            return ""
        case .exactly(let v):
            return "==\(v.semverName)"
        }
    }
    
    func formatDepenency(dep: (Package, VersionSpecifier)) -> String {
        "\(dep.0.name)\(self.versionSpecStr(dep.1))"
    }
    
    func packageTemplateSubstitutions(package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions = [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.semverName,
            "$DEPENDENCIES_COMMA_SEP" : dependencies.map(self.formatDepenency).map {$0.quoted()}.joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func mainTemplateSubstitutions(dependencies: [(Package, VersionSpecifier)]) -> [String : String] {
        let substitutions = [
            "$DIST_DIR" : self.genBinPathDir,
            "$DEPENDENCIES_LINE_SEP" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        return substitutions
    }
    
    func publish(package: Package, version: Version, sourceDir: String) {
        let pkgDir = "\(sourceDir)\(package.name)/\(version.directoryName)/"
//        print("Building: \(pkgDir)")
        try! shellOut(to: "python3 setup.py bdist_wheel", at: pkgDir)
        try! shellOut(to: "cp \(pkgDir)dist/*.whl \(self.genBinPathDir)")
    }
    
    
    func solveCommand(forMainPath mainPath: String) -> SolveCommand {
        let solver = SolveCommand(directory: mainPath, command: """
            export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/donaldpinckney/.local/bin"
            rm -rf env;
            python3 -m venv --upgrade-deps env;
            source env/bin/activate;
            pip3 install -q -r requirements.txt &&
            python3 main.py &&
            deactivate
        """)
        
        return solver
    }
}
