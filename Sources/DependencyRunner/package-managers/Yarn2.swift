import Files
import ShellOut

public struct Yarn2 : PackageManagerVerdaccioBased {
    public init() {}

    public let name = "yarn2"
    
    let solveCommandString =
    """
        rm -rf ~/.yarn/berry/cache
        yarn set version berry
        yarn config set npmRegistryServer http://localhost:4873
        yarn config set unsafeHttpWhitelist localhost
        yarn install --silent
        yarn node main.js
    """
}
