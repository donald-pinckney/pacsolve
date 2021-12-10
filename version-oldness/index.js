const semver = require('semver')
const pacote = require('pacote')
// const SemVer = require('semver/classes/semver')

const args = process.argv.slice(2);
const name = args[0]
const versionStr = args[1]
const requestedVersion = semver.parse(versionStr, {loose: true})



pacote.packument(name).then(manifest => {
  const allVersions = Object.keys(manifest.versions).map(v => semver.parse(v, {loose: true}))
  const sortedVersions = allVersions.sort((v1, v2) => v2.compare(v1))
  // console.log(sortedVersions)

  let foundIndex = -1
  for (let index = 0; index < sortedVersions.length; index++) {
    const v = sortedVersions[index];
    if(v.compare(requestedVersion) == 0) {
      foundIndex = index
      break
    }
  }

  if(foundIndex == -1) {
    console.log("UNKNOWN_VERSION")
    process.exit(1)
  }

  let oldness = null
  if(sortedVersions.length == 1) {
    oldness = 0
  } else {
    oldness = foundIndex / (sortedVersions.length - 1)
  }
  console.log(oldness)
})
