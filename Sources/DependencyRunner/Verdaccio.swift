//
//  File.swift
//  
//
//  Created by Donald Pinckney on 3/27/21.
//

import Foundation
import ShellOut

func startVerdaccio(name: String) {
    killVerdaccio()
    
    // We have to trick newer versions of npm into thinking that it is logged into the verdaccio server
    try! shellOut(to: "npm", arguments: ["config", "set", "//localhost:4873/:_authToken=\\\"stuff\\\""])
    
    let p = Process()
    p.launchPath = "Scripts/verdaccio/init_registry.sh"
    p.standardInput = FileHandle.nullDevice
    p.standardError = FileHandle.nullDevice
    p.standardOutput = FileHandle.nullDevice
    p.arguments = [name]
    p.launch()
    sleep(2) // We sleep 2 seconds to give Verdaccio server time to startup.
    // TODO: replace this with reading the stdout to see when it says it is ready
}

func killVerdaccio() {
    _ = try? shellOut(to: "killall", arguments: ["node"])
    _ = try? shellOut(to: "killall", arguments: ["Verdaccio"])
}
