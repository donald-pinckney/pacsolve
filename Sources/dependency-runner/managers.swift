import Files
import ShellOut

protocol PackageManager {
    var name : String { get }
    func generate(inSourceDir: String, binDir: String, dependencies: Dependencies) -> SolveCommand
}

enum SolveResult : CustomStringConvertible {
    var description: String {
        get {
            switch self {
            case .solveOk(let str): return "Dependency resolution tree:\n\n\(str)\n"
            case .solveError(let err): return "ERROR SOLVING DEPENDENCIES. ERROR MESSAGE: \n\(err)"
            }
        }
    }
    
    case solveOk(String)
    case solveError(String)
}

struct SolveCommand {
    let directory: String
    let command: String
    
    func solve() -> SolveResult {
        print("Solving dependencies...\n")
        do {
            let output = try shellOut(to: command, at: directory)
            return .solveOk(output)
        } catch {
            return .solveError("\(error)")
        }
    }
}

func mkdir_p(path: String) {
    try! shellOut(to: "mkdir", arguments: ["-p", path])
}

extension PackageManager {
    func generate(dependencies: Dependencies) -> SolveCommand {
        if let genFolder = try? Folder(path: "/Users/donaldpinckney/Research/packages/dependency-runner/generated/") {
            try! genFolder.delete()
        }
        
        print("Generating dependencies...")

        let sourcesPath = "/Users/donaldpinckney/Research/packages/dependency-runner/generated/\(self.name)/sources/"
        let binPath = "/Users/donaldpinckney/Research/packages/dependency-runner/generated/\(self.name)/bin/"
        mkdir_p(path: sourcesPath)
        mkdir_p(path: binPath)
        return generate(inSourceDir: sourcesPath, binDir: binPath, dependencies: dependencies)
    }
    
    var mainTemplateDir: Folder {
        get {
            try! Folder(path: "/Users/donaldpinckney/Research/packages/dependency-runner/Templates/\(self.name)/main/")
        }
    }
    
    var packageTemplateDir: Folder {
        get {
            try! Folder(path: "/Users/donaldpinckney/Research/packages/dependency-runner/Templates/\(self.name)/package/")
        }
    }
}

extension Dependencies {
    func allPackages() -> [Package] {
        var pkgs: Set<Package> = Set()
        
        for (pkg, pkg_deps) in self.non_main_deps {
            pkgs.insert(pkg)
            for (_, ds) in pkg_deps {
                for (p, _) in ds {
                    pkgs.insert(p)
                }
            }
        }
        
        return [Package](pkgs)
    }
}


extension String {
    func quoted() -> String {
        "'\(self)'"
    }
}

struct Pip : PackageManager {
    let name = "pip"
    
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
    
    func generate(inDir: String, package: Package, version: Version, dependencies: [(Package, VersionSpecifier)]) {
        let destParentDir = "\(inDir)\(package.name)/"
        mkdir_p(path: destParentDir)
        let destParentFolder = try! Folder(path: destParentDir)
        
        try! self.packageTemplateDir.copy(to: destParentFolder)
        
        let tmpFolder = try! Folder(path: "\(destParentDir)\(self.packageTemplateDir.name)")
        try! tmpFolder.rename(to: version.directoryName)
        
        let destFolder = try! Folder(path: "\(destParentDir)\(version.directoryName)")

//        print("Generating:\n\tPackage: \(destFolder.path)\n\tdependencies:\(dependencies)\n")

        
        let substitutions = [
            "$NAME_STRING" : package.name,
            "$VERSION_STRING" : version.semverName,
            "$DEPENDENCIES_COMMA_SEP" : dependencies.map(self.formatDepenency).map {$0.quoted()}.joined(separator: ", \n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        for f in destFolder.files.recursive {
            rewriteTemplate(file: f, substitutions: substitutions)
        }
        
        for f in destFolder.subfolders.recursive {
            rewriteTemplate(folder: f, substitutions: substitutions)
        }
    }
    
    func generateMain(inDir: String, binDir: String, dependencies: [(Package, VersionSpecifier)]) -> String {
        let mainPkgName = "__main_pkg__"
        
        let destParentDir = inDir
        mkdir_p(path: destParentDir)
        let destParentFolder = try! Folder(path: destParentDir)
        
        try! self.mainTemplateDir.copy(to: destParentFolder)
        
        let tmpFolder = try! Folder(path: "\(destParentDir)\(self.mainTemplateDir.name)")
        try! tmpFolder.rename(to: mainPkgName)
        
        let destFolder = try! Folder(path: "\(destParentDir)\(mainPkgName)")

//        print("Generating:\n\tMain package: \(destFolder)\n\tdependencies:\(dependencies)\n")
        
        let substitutions = [
            "$DIST_DIR" : binDir,
            "$DEPENDENCIES_LINE_SEP" : dependencies.map(self.formatDepenency).joined(separator: "\n"),
            "$DEPENDENCY_IMPORTS" : dependencies.map() { "import " + $0.0.name }.joined(separator: "\n"),
            "$DEPENDENCY_TREE_CALLS" : dependencies.map() { "\($0.0.name).dep_tree(indent + 1)" }.joined(separator: "\n    ")
        ]
        for f in destFolder.files.recursive {
            rewriteTemplate(file: f, substitutions: substitutions)
        }
        
        for f in destFolder.subfolders.recursive {
            rewriteTemplate(folder: f, substitutions: substitutions)
        }
        
        return destFolder.path
    }
    
    func build(package: Package, version: Version, sourceDir: String, binDir: String) {
        let pkgDir = "\(sourceDir)\(package.name)/\(version.directoryName)/"
//        print("Building: \(pkgDir)")
        try! shellOut(to: "python3 setup.py bdist_wheel", at: pkgDir)
        try! shellOut(to: "cp \(pkgDir)dist/*.whl \(binDir)")
    }

    func generate(inSourceDir: String, binDir: String, dependencies: Dependencies) -> SolveCommand {
        let pkgs = dependencies.allPackages()
        for pkg in pkgs {
            for v in pkg.versions {
                let deps = dependencies.non_main_deps[pkg]?[v] ?? []
                generate(inDir: inSourceDir, package: pkg, version: v, dependencies: deps)
            }
        }
        
        let mainPath = generateMain(inDir: inSourceDir, binDir: binDir, dependencies: dependencies.main_deps)
        
        for pkg in pkgs {
            for v in pkg.versions {
                build(package: pkg, version: v, sourceDir: inSourceDir, binDir: binDir)
            }
        }
                
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
