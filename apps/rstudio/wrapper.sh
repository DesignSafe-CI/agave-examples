# RStudio wrapper for DesignSafe on designsafe-exec-01

set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

echo job $JOB_ID execution at: `date`

# our node name
NODE_HOSTNAME=`hostname -s`
echo "running on node $NODE_HOSTNAME"

## Agave job id for rstudio password
RPASS='${AGAVE_JOB_ID}'

#agave callback to let it know the job is running
${AGAVE_JOB_CALLBACK_RUNNING}


port=$(( ((RANDOM<<15)|RANDOM) % 100 + 5900 ))
quit=0

while [ "$quit" -ne 1 ]; do
  netstat -a | grep $port >> /dev/null
  if [ $? -gt 0 ]; then
    quit=1
  else
    port=`expr $port + 1`
  fi
done
echo "Using port=$port"
WEBSOCKET_PORT=$port
LOGIN_VNC_PORT=$port

#notifications sent to designsafe, designsafeci-dev
### may need to move these calls into the docker container for proper timing
curl -k --data "event_type=VNC&host=$NODE_HOSTNAME.tacc.utexas.edu&port=$port&password=$RPASS&address=$NODE_HOSTNAME.tacc.utexas.edu:$port" https://designsafeci-dev.tacc.utexas.edu/webhooks/ &
curl -k --data "event_type=VNC&host=$NODE_HOSTNAME.tacc.utexas.edu&port=$port&password=$RPASS&address=$NODE_HOSTNAME.tacc.utexas.edu:$port" https://www.designsafe-ci.org/webhooks/ &


docker run -i --sig-proxy=true --rm \
  -p $port:8787 \
  -v "/corral-repl/tacc/NHERI/shared/${AGAVE_JOB_OWNER}":"/home/rstudio/mydata" \
  -v /corral-repl/tacc/NHERI/public/projects:/home/rstudio/public/nees:ro \
  -e PASSWORD="$VNCP" \
  stevemock/designsafe-rstudio /bin/bash -c /init


echo job execution finished at: `date`

cd ..

if [ ! $? ]; then
        echo "VNC exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi
