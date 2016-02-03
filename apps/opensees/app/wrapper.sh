#!/bin/bash

set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}

OPENSEES_BIN=/path/to/opensees/bin/OpenSeesSP

# Run the script with the runtime values passed in from the job request
module load petsc
$OPENSEES_BIN < ${input_script}

if [ ! $? ]; then
	echo "OpenSeesSP exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi
