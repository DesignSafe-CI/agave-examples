set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}
# Run the script with the runtime values passed in from the job request
#PREFIX=/corral-repl/tacc/NHERI/shared/${AGAVE_JOB_OWNER}

# just grab the filename if they dropped in the entire agave url (works if they didn't as well)
echo "inputScript is ${inputScript}"
INPUTSCRIPT='${inputScript}'
echo "INPUTSCRIPT is $INPUTSCRIPT"
TCLSCRIPT="${INPUTSCRIPT##*/}"

echo "TCLSCRIPT is $TCLSCRIPT"

docker run -i --sig-proxy=true --rm \
			-m 1G --name "opensees-${AGAVE_JOB_OWNER}"\
			-v "`pwd`/${inputDirectory}":"/data/" \
			stevemock/designsafe-opensees-express /bin/sh -c "cd /data ; OpenSees < /data/$TCLSCRIPT"

if [ ! $? ]; then
	echo "Docker container exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi

#docker rmi stevemock/docker-opensees
