#!/bin/bash

DIR=$( cd "$( dirname "$0" )" && pwd )

# set test variables
export inputDirectory="testInput"
export AGAVE_JOB_MEMORY_PER_NODE=1
export AGAVE_JOB_NAME=OpenFoam_Test

# stage file to root as it would be during a run
cp $DIR/$inputDirectory $DIR/../

# call wrapper script as if the values had been injected by the API
sh -c ../wrapper.sh

# clean up after the run completes
rm $DIR/../$inputDirectory
