#/bin/bash
TARBALL_DIR=$1
CURPATH=$(pwd)

# catch ctrl+c and exit
trap "echo 'Exiting...'; exit" INT

# block to create res directory
# if it exists, ask user to clear the directory
if [ -d "./resdir" ]; then
  echo "resdir exists, do you want to clear it? (y/[n])"
  read -r answer
  if [ "$answer" = "y" ]; then
    rm -rf "./resdir"
    mkdir -p "./resdir"
  else
    echo "aborting"
    exit
  fi
else
    mkdir -p "./resdir"
fi

# create temp dir for unpacking tarballs
if [ -d "./tmp" ]; then
  rm -rf "./tmp"
fi
mkdir -p "./tmp"

# variables to keep the count of failed/pass
TARBALL_COUNT=0
PASSED_COUNT=0

while read -r tarball; do
  # some vars
  TMPDIR="./tmp/$tarball"
  RESPATH=$(realpath "./resdir/$tarball")
  ABSOLUTEPATH=$(realpath $TARBALL_DIR/$tarball)

  # creating dirs
  mkdir -p $TMPDIR
  mkdir -p $RESPATH

  # unpack tarball
  echo "unpacking and running $tarball"
  cd $TMPDIR
  tar xvf $ABSOLUTEPATH > /dev/null
  cd "package"

  # run npm stuff
  echo "installing..."
  { time npm install --ignore-scripts > "$RESPATH/install_stdout.txt" 2> "$RESPATH/install_stderr.txt"; } 2> "$RESPATH/install_time.txt"
  echo $? > "$RESPATH/install_status.txt"
  echo "installing done: $(cat $RESPATH/install_status.txt)"
  echo "building..."
  { time npm run build > "$RESPATH/build_stdout.txt" 2> "$RESPATH/build_stderr.txt"; } 2> "$RESPATH/build_time.txt"
  echo $? > "$RESPATH/build_status.txt"
  echo "buidling done: $(cat $RESPATH/build_status.txt)"
  echo "testing..."
  { time npm run test > "$RESPATH/test_stdout.txt" 2> "$RESPATH/test_stderr.txt"; } 2> "$RESPATH/test_time.txt"
  TEST_STATUS=$?
  echo $TEST_STATUS > "$RESPATH/test_status.txt"
  # if the code is 0, we increase the pass counter
  if [ $TEST_STATUS -eq 0 ]; then
    PASSED_COUNT=$((PASSED_COUNT+1))
  fi
  echo "testing done: $TEST_STATUS"

  # increase counter
  TARBALL_COUNT=$((TARBALL_COUNT+1))
  echo "$TARBALL_COUNT"

  # go back to original path
  cd $CURPATH
done < <(ls $TARBALL_DIR)

PASSFAIL="pass rate: $PASSED_COUNT/$TARBALL_COUNT"
echo $PASSFAIL
echo $PASSFAIL > "./resdir/totals.txt"

# clean up
rm -fr "./tmp"
