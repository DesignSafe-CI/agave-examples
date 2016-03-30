# VNC/Matlab wrapper for DesignSafe on Stampede

set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

echo job $JOB_ID execution at: `date`

# our node name
NODE_HOSTNAME=`hostname -s`
echo "running on node $NODE_HOSTNAME"

## experiment for vncpasswords
VNCP='${AGAVE_JOB_ID}'
VNCPO=`/home/tg458981/bin/vncp $VNCP`

# VNC server executable
VNCSERVER_BIN=`which vncserver`
echo "using default VNC server $VNCSERVER_BIN"

# set memory limits to 95% of total memory to prevent node death
# NODE_MEMORY=`free -k | grep ^Mem: | awk '{ print $2; }'`
# NODE_MEMORY_LIMIT=`echo "0.95 * $NODE_MEMORY / 1" | bc`
# ulimit -v $NODE_MEMORY_LIMIT -m $NODE_MEMORY_LIMIT
# echo "memory limit set to $NODE_MEMORY_LIMIT kilobytes"

# launch VNC session with the session password set to the agave job id
VNC_DISPLAY=`$VNCSERVER_BIN -rfbauth vncp.txt $@ 2>&1 | grep desktop | awk -F: '{print $3}'`
echo "got VNC display :$VNC_DISPLAY"

# todo: make sure this is a valid display, and that it is 1 or 2, since those are the only displays forwarded
# using our iptables scripts
########### THIS ALL NEEDS WORK TO BE GOOD FOR A VM INSTEAD OF HPC machine
if [ x$VNC_DISPLAY == "x" ]; then
    echo
    echo "===================================================="
    echo "   Error launching vncserver: $VNCSERVER"
    echo "   Please submit a ticket to the TACC User Portal"
    echo "   http://portal.tacc.utexas.edu/"
    echo "===================================================="
    echo
    exit 1
fi

LOCAL_VNC_PORT=`expr 5900 + $VNC_DISPLAY`
echo "local (compute node) VNC port is $LOCAL_VNC_PORT"

fire up websockify to turn the vnc session connection into a websocket connection
#STUFF=`/usr/bin/websockify/run --cert=/home1/00832/envision/.viscert/vis.2015.04.pem -D 5902 localhost:$LOCAL_VNC_PORT`
## TODO get certs for designsafe-exec-01 and use them
STUFF=`/usr/bin/websockify -D 5902 localhost:$LOCAL_VNC_PORT`

echo "output from websockify: $STUFF"

#same because on a VM
echo "got login node VNC port $LOCAL_VNC_PORT"

# set display for X applications
export DISPLAY=":$VNC_DISPLAY"

# info for TACC Visualization Portal / designsafe notification
#echo "stampede.tacc.utexas.edu" > .envision_address
echo ":$VNC_DISPLAY" > .envision_display
echo "$LOGIN_VNC_PORT" > .envision_vnc_port
echo "$SLURM_JOB_ID" > .envision_job_id

# stampede specific port offset + 10,000 for websocket port from websockify
## TODO fix for VM
##WEBSOCKET_PORT=$(($LOGIN_VNC_PORT + 10000))

# write job start time and duration (in hours) to file
date +%s > .envision_job_start
echo "4" > .envision_job_duration
echo "success" > .envision_status

#agave callback to let it know the job is running
${AGAVE_JOB_CALLBACK_RUNNING}
#notifications sent to designsafe, designsafeci-dev, and requestbin
curl -k --data "event_type=VNC&host=vis.tacc.utexas.edu&port=$WEBSOCKET_PORT&address=vis.tacc.utexas.edu:$LOGIN_VNC_PORT&password=$VNCP&owner=${AGAVE_JOB_OWNER}" https://designsafeci-dev.tacc.utexas.edu/webhooks/ &
curl -k --data "event_type=VNC&host=vis.tacc.utexas.edu&port=$WEBSOCKET_PORT&address=vis.tacc.utexas.edu:$LOGIN_VNC_PORT&password=$VNCP&owner=${AGAVE_JOB_OWNER}" https://www.designsafe-ci.org/webhooks/ &
curl -k --data "event_type=VNC&host=vis.tacc.utexas.edu&port=$WEBSOCKET_PORT&address=vis.tacc.utexas.edu:$LOGIN_VNC_PORT&password=$VNCP&owner=${AGAVE_JOB_OWNER}" http://requestbin.agaveapi.co/v946vov9 &

# cd to the input directory and run the application with the runtime
#values passed in from the job request
cd ${workingDirectory}
CWD=${workingDirectory}

# run matlab: BLOCKS HERE??. If matlab is closed, then the job ends
##matlab ## SEE BELOW XTERM

# run an xterm for the user; execution will hold here
xterm -r -ls -geometry 80x24+10+10 -title '*** Exit this window to kill your VNC server ***' -e 'matlab'


# job is done!

echo "Killing VGL client"
kill $VGL_PID


echo "Killing VNC server"
vncserver -kill $DISPLAY

# wait a brief moment so vncserver can clean up after itself
sleep 1

echo job execution finished at: `date`

cd ..

if [ ! $? ]; then
        echo "VNC exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi
