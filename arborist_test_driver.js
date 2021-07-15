const Arborist = require('./arborist')
const fs = require('fs')

const args = process.argv.slice(2)
const path = args[0]

try {
  fs.rmSync(path + "node_modules/", {recursive: true})
  fs.rmSync(path + "package-lock.json")
} catch {

}

const arb = new Arborist({
  // options object

  // where we're doing stuff.  defaults to cwd.
  path: path,

  // url to the default registry.  defaults to npm's default registry
  registry: 'http://localhost:4873/',
  '//localhost:4873/:_authToken': "stuff",
})

arb.buildIdealTree({useRosetteSolver: true, rosetteSolverPath: "RosetteSolver/rosette-solver.rkt"}).then(() => {
  arb.reify({
    save: true
  }).then(() => {
    console.log("done")
  })
})