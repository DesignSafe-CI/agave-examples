
set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}

OPENSEES_BIN=/work/00849/tg458981/stampede/DesignSafe/apps/opensees/bin/OpenSeesSP

# Run the script with the runtime values passed in from the job request
module load petsc
cd ${inputDirectory}
$OPENSEES_BIN < ${inputScript}
cd ..

if [ ! $? ]; then
        echo "OpenSeesSP exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi
