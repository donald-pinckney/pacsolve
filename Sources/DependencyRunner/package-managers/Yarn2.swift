import Files
import ShellOut

struct Yarn2 : PackageManagerVerdaccioBased {
    init() {}

    let uniqueName = "yarn2"
    
    func solveCommand(package: Package, version: Version) -> String {
        """
            rm -rf ~/.yarn/berry/cache
            yarn set version berry
            yarn config set npmRegistryServer http://localhost:4873
            yarn config set unsafeHttpWhitelist localhost
            yarn install --silent
            yarn node index.js
        """
    }
}
