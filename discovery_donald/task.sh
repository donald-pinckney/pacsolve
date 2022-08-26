#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <task_name>"
    exit 1
fi


module load discovery nodejs
export PATH=/home/pinckney.d/.local/bin/:$PATH
# export PATH=/work/arjunguha-research-group/arjun/maxnpm/./node_modules/.bin:$PATH

export Z3_ABS_PATH=/work/arjunguha-research-group/pacsolve/z3/build/z3
export Z3_ADD_MODEL_OPTION=True

DIR=$1

set -x
set -e

rm -rf node_modules package-lock.json

CACHE_DIR=`mktemp -d`
export npm_config_cache=$CACHE_DIR

WORKDIR=`mktemp -d`

#trap "rm -rf $CACHE_DIR $WORKDIR" EXIT

cp -r $DIR/ $WORKDIR/

cd $WORKDIR/package


echo "*** Trying vanilla ***"
if [ ! -f vanilla-lockfile.json ]; then
    maxnpm install --prefer-offline --no-audit --omit dev --omit peer --omit optional --ignore-scripts --legacy-peer-deps
    cp node_modules/.package-lock.json $DIR/vanilla-lockfile.json
    rm -rf node_modules package-lock.json
fi

echo "*** Trying audit fix ***"
if [ ! -f auditfix-lockfile.json ]; then
    maxnpm install --prefer-offline --no-audit --omit dev --omit peer --omit optional --ignore-scripts --legacy-peer-deps
    maxnpm audit fix --omit dev --omit peer --omit optional --prefer-offline --ignore-scripts --audit-level=none --legacy-peer-deps || true
    cp node_modules/.package-lock.json $DIR/auditfix-lockfile.json
    rm -rf node_modules package-lock.json
fi

echo "*** Trying audit fix --force ***"
if [ ! -f auditfixforce-lockfile.json ]; then
    maxnpm install --prefer-offline --no-audit --omit dev --omit peer --omit optional --ignore-scripts --legacy-peer-deps
    maxnpm audit fix --force --omit dev --omit peer --omit optional --prefer-offline --ignore-scripts --audit-level=none --legacy-peer-deps || true
    cp node_modules/.package-lock.json $DIR/auditfixforce-lockfile.json
    rm -rf node_modules package-lock.json
fi


echo "*** Trying maxnpm min_cve,min_oldness ***"
if [ ! -f maxnpmcveoldness-lockfile.json ]; then
maxnpm install --no-audit --prefer-offline --rosette --ignore-scripts --consistency npm --minimize min_cve,min_oldness
cp node_modules/.package-lock.json $DIR/maxnpmcveoldness-lockfile.json
rm -rf node_modules package-lock.json
fi

exit 0

if [ ! -f maxnpmoldnesscve-lockfile.json ]; then
    maxnpm install --no-audit --prefer-offline --rosette --ignore-scripts --consistency npm --minimize min_oldness,min_cve
    cp node_modules/.package-lock.json $DIR/maxnpmoldnesscve-lockfile.json
    rm -rf node_modules package-lock.json
fi
