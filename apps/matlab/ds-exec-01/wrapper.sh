# VNC/Matlab wrapper for DesignSafe on Stampede

set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

echo job $JOB_ID execution at: `date`

# our node name
NODE_HOSTNAME=`hostname -s`
echo "running on node $NODE_HOSTNAME"

## Agave job id for vncpassword
VNCP='${AGAVE_JOB_ID}'
#VNCPO=`/home/tg458981/bin/vncp $VNCP`

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
curl -k --data "event_type=VNC&host=designsafe-exec-01.tacc.utexas.edu&port=$port&password=$VNCP&address=designsafe-exec-01.tacc.utexas.edu:$port/vnc.html?password=$VNCP&port=$port&owner=${AGAVE_JOB_OWNER}&autoconnect=true" https://designsafeci-dev.tacc.utexas.edu/webhooks/ &
curl -k --data "event_type=VNC&host=designsafe-exec-01.tacc.utexas.edu&port=$port&password=$VNCP&address=designsafe-exec-01.tacc.utexas.edu:$port/vnc.html?password=$VNCP&port=$port&owner=${AGAVE_JOB_OWNER}&autoconnect=true" https://www.designsafe-ci.org/webhooks/ &

docker run -i --sig-proxy=true --rm \
  -p $port:6080 \
  -v "/corral-repl/tacc/NHERI/shared/${AGAVE_JOB_OWNER}":"/home/ubuntu/mydata" \
  -v /home/mock/matlab:/matlab \
  -v /corral-repl/tacc/NHERI/public/projects:/home/ubuntu/public/nees:ro \
  --env VNCP="$VNCP" --env DESKTOP_RESOLUTION="${desktop_resolution}" \
  vnc-matlab

#docker run -i --sig-proxy=true --rm \
#			-m 1G \
#			-v "`pwd`/${inputDirectory}":"/data/" \
#      -v "blahblah ${AGAVE_JOB_OWNER} blah blah": "something ${AGAVE_JOB_OWNER}" \
#			stevemock/designsafe-opensees-express
# job is done!

echo job execution finished at: `date`

cd ..

if [ ! $? ]; then
        echo "VNC exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi
