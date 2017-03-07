set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}
# Run the script with the runtime values passed in from the job request
PREFIX="/corral-repl/tacc/NHERI/shared/"
AGAVEPREFIX='agave://designsafe.storage.default/'

# just grab the filename if they dropped in the entire agave url (works if they didn't as well)
#echo "inputFile is ${inputFile}"
PARENTDIR="$(dirname "${inputFile}")"

#echo "parent dir is $PARENTDIR"
#outputs: 'agave://designsafe.storage.default/mock/extract'

DIRNAME=${PARENTDIR#${AGAVEPREFIX}}

#echo "dir is $DIRNAME"

FULLPATH=$PREFIX$DIRNAME

#echo "FULLPATH = $FULLPATH"

INPUTFILE='${inputFile}'
#echo "INPUTFILE is $INPUTFILE"
EXTRACTFILE="${INPUTFILE##*/}"

#echo "EXTRACTFILE is $EXTRACTFILE"

cd $FULLPATH
echo `pwd`

shopt -s nocasematch
if [[ $EXTRACTFILE =~ \.t?gz$ ]];then
  tar xzf $EXTRACTFILE;
elif [[ $EXTRACTFILE =~ \.tar\.gz$ ]];then
  tar xzf $EXTRACTFILE;
elif [[ $EXTRACTFILE =~ \.tar$ ]];then
	tar xf $EXTRACTFILE;
elif [[ $EXTRACTFILE =~ \.gz$ ]];then
	gunzip $EXTRACTFILE;
elif [[ $EXTRACTFILE =~ \.zip$ ]];then
  unzip $EXTRACTFILE;
else
	echo 'unrecoginized file extension'
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit 1;
fi
shopt -u nocasematch

if [ ! $? ]; then
	echo "Extract exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi
