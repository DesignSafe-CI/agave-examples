set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}

cd ${inputDirectory}

# Run the script with the runtime values passed in from the job request
PREFIX="/corral-repl/tacc/NHERI/shared/"
AGAVEPREFIX='agave://designsafe.storage.default/'

# just grab the filename if they dropped in the entire agave url (works if they didn't as well)
#echo "inputFile is ${inputFile}"
PARENTDIR="$(dirname "${inputFile}")"

echo "parent dir is $PARENTDIR"
#outputs: 'agave://designsafe.storage.default/mock/extract'

DIRNAME=${PARENTDIR#${AGAVEPREFIX}}

echo "dir is $DIRNAME"

FULLPATH=$PREFIX$DIRNAME

echo "FULLPATH = $FULLPATH"

INPUTFILE='${inputFile}'
echo "INPUTFILE is $INPUTFILE"
FIGFILE="${INPUTFILE##*/}"

echo "FIGFILE is $FIGFILE"

echo `pwd`
ls -l

docker run -i --sig-proxy=true --rm \
			-m 1G \
			-v "`pwd`":"/data/" \
			stevemock/figuregen-docker /bin/sh -c "FigureGen.out -I /data/$FIGFILE"

if [ ! $? ]; then
	echo "FigureGen exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi
