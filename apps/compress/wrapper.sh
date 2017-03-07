set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}
# Run the script with the runtime values passed in from the job request
PREFIX="/corral-repl/tacc/NHERI/shared/"
AGAVEPREFIX='agave://designsafe.storage.default/'

# just grab the filename if they dropped in the entire agave url (works if they didn't as well)
#echo "inputFile is ${inputFile}"
PARENTDIR="$(dirname "${directory}")"

#echo "parent dir is $PARENTDIR"
#outputs: 'agave://designsafe.storage.default/mock/compress'

DIRNAME=${PARENTDIR#${AGAVEPREFIX}}

echo "dir is $DIRNAME"

FULLPATH=$PREFIX$DIRNAME

echo "FULLPATH = $FULLPATH"

INPUTFILE='${directory}'
echo "INPUTFILE is $INPUTFILE"
COMPRESSFILE="${INPUTFILE##*/}"

echo "COMPRESSFILE is $COMPRESSFILE"

cd $FULLPATH
echo `pwd`

shopt -s nocasematch
if [ ! -d $COMPRESSFILE ]; then
  echo 'Input $COMPRESSFILE is not a directory.'
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit 1;
fi

echo "compression_type is ${compression_type}"
CTYPE='${compression_type}'
if [ "$CTYPE" = "tgz" ]; then
  echo 'tarring'
  tar czvf $COMPRESSFILE.tar.gz $COMPRESSFILE;
else
  echo 'zipping'
  zip -r $COMPRESSFILE.zip $COMPRESSFILE;
fi
shopt -u nocasematch

if [ ! $? ]; then
	echo "Compress exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi
