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

INPUT_ARG=$1
DIR=${INPUT_ARG%/*}
LOCKPATH=${INPUT_ARG##*/} 

echo $DIR
echo $LOCKPATH



set -x
set -e

rm -rf node_modules package-lock.json

CACHE_DIR=`mktemp -d`
export npm_config_cache=$CACHE_DIR

WORKDIR=`mktemp -d`

#trap "rm -rf $CACHE_DIR $WORKDIR" EXIT

cp -r $DIR/ $WORKDIR/

cd $WORKDIR/package

rm -rf node_modules package-lock.json

if [ -f $LOCKPATH ]; then
    echo "$LOCKPATH exists, skipping"
    exit 0
fi


if [ "$LOCKPATH" = "vanilla-lockfile.json" ]; then
    echo "*** Trying vanilla ***"
    maxnpm install --prefer-offline --no-audit --omit dev --omit peer --omit optional --ignore-scripts --legacy-peer-deps
fi

if [ "$LOCKPATH" = "auditfix-lockfile.json" ]; then
    echo "*** Trying audit fix ***"
    maxnpm install --prefer-offline --no-audit --omit dev --omit peer --omit optional --ignore-scripts --legacy-peer-deps
    maxnpm audit fix --omit dev --omit peer --omit optional --prefer-offline --ignore-scripts --audit-level=none --legacy-peer-deps || true
fi

if [ "$LOCKPATH" = "auditfixforce-lockfile.json" ]; then
    echo "*** Trying audit fix --force ***"
    maxnpm install --prefer-offline --no-audit --omit dev --omit peer --omit optional --ignore-scripts --legacy-peer-deps
    maxnpm audit fix --force --omit dev --omit peer --omit optional --prefer-offline --ignore-scripts --audit-level=none --legacy-peer-deps || true
fi


if [ "$LOCKPATH" = "maxnpmcveoldness-lockfile.json" ]; then
    echo "*** Trying maxnpm min_cve,min_oldness ***"
    maxnpm install --no-audit --prefer-offline --rosette --ignore-scripts --consistency npm --minimize min_cve,min_oldness
fi


if [ "$LOCKPATH" = "maxnpmcveoldness_pip-else-npm-lockfile.json" ]; then
    echo "*** Trying maxnpm min_cve,min_oldness pip-else-npm ***"
    maxnpm install --no-audit --prefer-offline --rosette --ignore-scripts --consistency pip-else-npm --minimize min_cve,min_oldness
fi

cp node_modules/.package-lock.json $DIR/$LOCKPATH
rm -rf node_modules package-lock.json

exit 0

if [ ! -f maxnpmoldnesscve-lockfile.json ]; then
    maxnpm install --no-audit --prefer-offline --rosette --ignore-scripts --consistency npm --minimize min_oldness,min_cve
    cp node_modules/.package-lock.json $DIR/maxnpmoldnesscve-lockfile.json
    rm -rf node_modules package-lock.json
fi
