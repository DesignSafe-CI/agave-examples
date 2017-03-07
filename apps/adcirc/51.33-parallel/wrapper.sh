set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

# Run the script with the runtime values passed in from the job request

${AGAVE_JOB_CALLBACK_RUNNING}

cd ${inputDirectory}

# generate the two prep files
CORES=$((${AGAVE_JOB_NODE_COUNT}*16))
echo "The cores for this run are $CORES"
rm -rf in.prep1 in.prep2 &>/dev/null
cat << EOT >> in.prep1
$CORES
1
${meshFile}
EOT

cat << EOT >> in.prep2
$CORES
2
EOT

# decompose the things
/work/00849/tg458981/stampede/DesignSafe/apps/adcirc/51.33/adcprep < in.prep1
/work/00849/tg458981/stampede/DesignSafe/apps/adcirc/51.33/adcprep < in.prep2

mkdir ./outputs

# run the things
ibrun /work/00849/tg458981/stampede/DesignSafe/apps/adcirc/51.33/padcirc -I . -O ./outputs >> output.eo.txt 2>&1
rm -rf outputs/PE*
cd ..

if [ ! $? ]; then
	echo "ADCIRC exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi

exit 0
