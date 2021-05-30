import Foundation
import ShellOut

extension SolutionGraph {
    private func dotCode() -> String {
        let nodes = self.vertices.enumerated().map { (idx, v) -> String in
            var attributes: [(String, String)]
            switch v {
            case .rootContext:
                attributes = [("label", "\"context\""), ("color", "\".7 .3 1.0\""), ("style", "filled"), ("shape", "box")]
            case let .resolvedPackage(package: p, version: v, data: _):
                attributes = [("label", "\"\(p)@\(v)\""), ("color", "\"gray88\""), ("fontcolor", "\"gray88\"")]
            }
            if idx == self.contextVertex {
                attributes += [("peripheries", "3")]
            }
            
            let attrString = attributes.map { (key, val) in "\(key)=\(val)" }.joined(separator: ",")
            
            return "node\(idx) [\(attrString)];"
        }.joined(separator: "\n")
        
        let edges = self.adjacencyLists.flatMap { (fromVert: Int, toVerts: Set<Int>) in
            toVerts.map { toVert in "node\(fromVert) -> node\(toVert) [color=\"gray88\"];" }
        }.joined(separator: "\n")
        
        return "digraph G {\ngraph [bgcolor=\"transparent\"];\n\(nodes)\n\(edges)\n}"
    }
    
    private func drawGraphToFile(_ d: GenDirManager) throws -> URL {
        let dotData = dotCode().data(using: .utf8)!
        let dotFile = try d.newTempFile(ext: "gv", contents: dotData)
        let imageFile = try d.newTempFile(ext: "pdf", contents: nil)
        try shellOut(to: "dot", arguments: ["-Tpdf", dotFile.path, "-Gdpi=192", "-o", imageFile.path])
        return imageFile
    }
    
    func graphDescription(inDirectory d: GenDirManager, hasIterm2: Bool) throws -> String {
        let imageFile = try drawGraphToFile(d)
        if hasIterm2 {
            let imageData = try Data(contentsOf: imageFile)
            return imageData.iTermPrintImage()
        } else {
            return imageFile.path
        }
    }
}

private extension Data {
    func isTmux() -> Bool {
        guard let termStr = ProcessInfo.processInfo.environment["TERM"] else {
            return false
        }
        return termStr.hasPrefix("screen")
    }
    
    func osc() -> String {
        if isTmux() {
            return "\u{001B}Ptmux;\033\033]"
        } else {
            return "\u{001B}]"
        }
    }
    func st() -> String {
        if isTmux() {
            return "\u{7}\u{001B}\\"
        } else {
            return "\u{7}"
        }
    }
    func iTermPrintImage() -> String {
        return osc() + "1337;File=size=\(self.count);inline=1:\(self.base64EncodedString())" + st()
    }
}
