# OpenFoam wrapper for DesignSafe

set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}

# Load the OpenFoam module
module load openfoam

# cd to the input directory and run the application with the runtime
#values passed in from the job request
cd ${inputDirectory}
blockMesh > blockMesh.log
decomposePar > decomposePar.log
ibrun ${solver} > ${solver}.log
cd ..

if [ ! $? ]; then
        echo "OpenFoam ${solver} exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi
