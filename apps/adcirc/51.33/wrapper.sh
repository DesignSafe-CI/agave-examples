set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

# Run the script with the runtime values passed in from the job request

${AGAVE_JOB_CALLBACK_RUNNING}

mkdir ./outputs
/work/00849/tg458981/stampede/DesignSafe/apps/adcirc/51.33/adcirc.bin -I ${inputDirectory} -O ./outputs >> output.eo.txt 2>&1

if [ ! $? ]; then
	echo "ADCIRC exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi

exit 0
