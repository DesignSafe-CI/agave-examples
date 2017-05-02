set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}
# Run the script with the runtime values passed in from the job request
PREFIX="/corral-repl/projects/NHERI/${directory}"

setfacl -m d:u:tg458981:rwX,u:${username}:rwX $PREFIX

getfacl $PREFIX

if [ ! $? ]; then
	echo "Extract exited with an error status. $?" >&2
	${AGAVE_JOB_CALLBACK_FAILURE}
	exit
fi
