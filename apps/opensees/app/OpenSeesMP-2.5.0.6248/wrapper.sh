
set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}
module load petsc

OPENSEES_BIN='/work/00849/tg458981/stampede/DesignSafe/apps/opensees/bin/OpenSeesMP-2.5.0.6248'

# just grab the filename if they dropped in the entire agave url (works if they didn't as well)
echo "inputScript is ${inputScript}"
INPUTSCRIPT='${inputScript}'
echo "INPUTSCRIPT is $INPUTSCRIPT"
TCLSCRIPT="${INPUTSCRIPT##*/}"

echo "TCLSCRIPT is $TCLSCRIPT"

# Run the script with the runtime values passed in from the job request
cd "${inputDirectory}"
OUT=`$OPENSEES_BIN < $TCLSCRIPT`
cd ..

ibrun $OPENSEES_BIN $TCLSCRIPT

cd ..

if [ ! $? ]; then
        echo "OpenSeesMP exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi
