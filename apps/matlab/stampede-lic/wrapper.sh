# VNC/Matlab wrapper for DesignSafe on Stampede

set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

# set up license file
cat << EOT >> .matlab_license
${_license}
EOT

cat .matlab_license
export LM_LICENSE_FILE=`pwd`/.matlab_license
echo "LM_LICENSE_FILE is : $LM_LICENSE_FILE"

# Load the default TACC modules
module purge
module load TACC
module load matlab

echo job $JOB_ID execution at: `date`

# our node name
NODE_HOSTNAME=`hostname -s`
echo "running on node $NODE_HOSTNAME"

## experiment for vncpasswords
VNCP='${AGAVE_JOB_ID}'
VNCPO=`/scratch/00849/tg458981/vncp $VNCP`

# VNC server executable
VNCSERVER_BIN=`which vncserver`
echo "using default VNC server $VNCSERVER_BIN"

# set memory limits to 95% of total memory to prevent node death
NODE_MEMORY=`free -k | grep ^Mem: | awk '{ print $2; }'`
NODE_MEMORY_LIMIT=`echo "0.95 * $NODE_MEMORY / 1" | bc`
ulimit -v $NODE_MEMORY_LIMIT -m $NODE_MEMORY_LIMIT
echo "memory limit set to $NODE_MEMORY_LIMIT kilobytes"

# set wayness, used for ibrun
WAYNESS=`echo $PE | perl -pe 's/([0-9]+)way/\1/;'`
echo "set wayness to $WAYNESS"

# launch VNC session with the session password set to the agave job id
VNC_DISPLAY=`$VNCSERVER_BIN -geometry ${desktop_resolution} -rfbauth vncp.txt $@ 2>&1 | grep desktop | awk -F: '{print $3}'`
echo "got VNC display :$VNC_DISPLAY"

# todo: make sure this is a valid display, and that it is 1 or 2, since those are the only displays forwarded
# using our iptables scripts

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

# fire up websockify to turn the vnc session connection into a websocket connection
STUFF=`/home1/00832/envision/websockify/run --cert=/home1/00832/envision/.viscert/vis.2015.04.pem -D 5902 localhost:$LOCAL_VNC_PORT`
echo $STUFF

#
# hackalicious direct map of rack to port range to support the lingering vestiges of Stampede
#
declare -A LOGIN_PORT_MAP_FOUR
declare -A LOGIN_PORT_MAP_FIVE
declare LOGIN_VNC_PORT
LOGIN_PORT_MAP_FOUR=( ["c442"]="580" ["c443"]="581" ["c444"]="582" ["c457"]="583" ["c458"]="584" ["c459"]="585"
["c460"]="586" ["c461"]="587" ["c462"]="588" ["c463"]="589" ["c464"]="590" ["c465"]="591" ["c478"]="592"
["c479"]="593" ["c480"]="594" ["c481"]="595" ["c482"]="596" ["c483"]="597" ["c484"]="598" ["c485"]="599"
["c486"]="600" ["c495"]="601" ["c496"]="602" ["c497"]="603" ["c498"]="604" ["c499"]="605" )
LOGIN_PORT_MAP_FIVE=( ["c500"]="235" ["c501"]="236" ["c502"]="237" ["c503"]="238" ["c504"]="239" ["c505"]="240"
["c506"]="241" ["c507"]="242" ["c508"]="243" ["c509"]="244" ["c510"]="245" ["c511"]="246" ["c512"]="247"
["c513"]="248" ["c514"]="249" ["c515"]="250" ["c516"]="251" ["c517"]="252" ["c518"]="253" ["c519"]="254"
["c520"]="255" ["c521"]="256" ["c522"]="257" ["c523"]="258" ["c524"]="259" ["c525"]="260" ["c526"]="261"
["c527"]="262" ["c528"]="263" ["c529"]="264" ["c530"]="265" ["c531"]="266" ["c532"]="267" ["c533"]="268"
["c534"]="269" ["c535"]="270" ["c536"]="271" ["c537"]="272" ["c538"]="273" ["c539"]="274" ["c540"]="275"
["c541"]="276" ["c542"]="277" ["c543"]="278" ["c544"]="279" ["c548"]="280" ["c549"]="281" ["c550"]="282"
["c551"]="283" ["c552"]="284" ["c553"]="285" ["c554"]="286" ["c555"]="287" ["c556"]="288" ["c557"]="289"
["c558"]="290" ["c559"]="291" ["c560"]="292" )
RACK_SET=`echo $NODE_HOSTNAME | perl -ne 'print $1 if /c(\d)\d\d-\d\d\d/;'`
echo "RACK_SET=$RACK_SET"
RACK=`echo $NODE_HOSTNAME | perl -ne 'print $1 if /(c\d\d\d)-\d\d\d/;'`
echo "RACK=$RACK"

if [ $RACK_SET -eq "4" ]; then
    LOGIN_VNC_PORT="${LOGIN_PORT_MAP_FOUR[$RACK]}`echo $NODE_HOSTNAME | perl -ne 'print $1.$2 if /c\d\d\d-(\d)\d(\d)/;'`"
    LOGIN_VNC_PORT=$(($LOGIN_VNC_PORT + 2600))
elif [ $RACK_SET -eq "5" ]; then
    LOGIN_VNC_PORT="${LOGIN_PORT_MAP_FIVE[$RACK]}`echo $NODE_HOSTNAME | perl -ne 'print $1.$2 if /c\d\d\d-(\d)\d(\d)/;'`"
    LOGIN_VNC_PORT=$(($LOGIN_VNC_PORT + 20000))
else
    echo
    echo "================================"
    echo "  unknown RACK_SET $RACK_SET    "
    echo "================================"
    echo
    exit 1
fi

#LOGIN_VNC_PORT="$VNC_DISPLAY`echo $NODE_HOSTNAME | perl -ne 'print 59$2 if /c\d(\d\d)-\d(\d\d)/;'`"
echo "got login node VNC port $LOGIN_VNC_PORT"

# create reverse tunnel port to login nodes.  Make one tunnel for each login so the user can just
# connect to stampede.tacc
for i in `seq 4`; do
   ssh -f -g -N -R $LOGIN_VNC_PORT:$NODE_HOSTNAME:$LOCAL_VNC_PORT login$i
done
echo "Created reverse ports on Stampede logins"

echo "Your VNC server is now running!"
echo "To connect via VNC client:  SSH tunnel port $LOGIN_VNC_PORT to stampede.tacc.utexas.edu:$LOGIN_VNC_PORT"
echo "                            Then connect to localhost::$LOGIN_VNC_PORT"
#echo
#echo "OR:                         Connect directly to login1.longhorn.tacc.utexas.edu::$LOGIN_VNC_PORT"
#echo

# set display for X applications
export DISPLAY=":$VNC_DISPLAY"


# Warn the user when their session is about to close
# see if the user set their own runtime
#TACC_RUNTIME=`qstat -j $JOB_ID | grep h_rt | perl -ne 'print $1 if /h_rt=(\d+)/'`  # qstat returns seconds
TACC_RUNTIME=`squeue -l -j $SLURM_JOB_ID | grep $SLURM_QUEUE | awk '{print $7}'` # squeue returns HH:MM:SS
if [ x"$TACC_RUNTIME" == "x" ]; then
   TACC_Q_RUNTIME=`sinfo -p $SLURM_QUEUE | grep -m 1 $SLURM_QUEUE | awk '{print $3}'`
   if [ x"$TACC_Q_RUNTIME" != "x" ]; then
       # pnav: this assumes format hh:dd:ss, will convert to seconds below
       #       if days are specified, this won't work
       TACC_RUNTIME=$TACC_Q_RUNTIME
   fi
fi

if [ x"$TACC_RUNTIME" != "x" ]; then
   # there's a runtime limit, so warn the user when the session will die
   # give 5 minute warning for runtimes > 5 minutes
       H=$((`echo $TACC_RUNTIME | awk -F: '{print $1}'` * 3600))
       M=$((`echo $TACC_RUNTIME | awk -F: '{print $2}'` * 60))
       S=`echo $TACC_RUNTIME | awk -F: '{print $3}'`
       TACC_RUNTIME_SEC=$(($H + $M + $S))

   if [ $TACC_RUNTIME_SEC -gt 300 ]; then
           TACC_RUNTIME_SEC=`expr $TACC_RUNTIME_SEC - 300`
           sleep $TACC_RUNTIME_SEC && echo "$USER's VNC session on $VNC_DISPLAY will end in 5 minutes.  Please save your work now." | wall &
       fi
fi


# we need vglclient to run to have graphics across multi-node jobs
vglclient >& /dev/null &
VGL_PID=$!

# info for TACC Visualization Portal / designsafe notification
#echo "stampede.tacc.utexas.edu" > .envision_address
#echo ":$VNC_DISPLAY" > .envision_display
#echo "$LOGIN_VNC_PORT" > .envision_vnc_port
#echo "$SLURM_JOB_ID" > .envision_job_id

# stampede specific port offset is calculated above dependent on which of the rack sets 4XXX or 5XXX
WEBSOCKET_PORT=$LOGIN_VNC_PORT

# write job start time and duration (in hours) to file
#date +%s > .envision_job_start
#echo "4" > .envision_job_duration
#echo "success" > .envision_status

#agave callback to let it know the job is running
${AGAVE_JOB_CALLBACK_RUNNING}
#notifications sent to designsafe, designsafeci-dev, and requestbin
curl -k --data "event_type=VNC&host=vis.tacc.utexas.edu&port=$WEBSOCKET_PORT&address=vis.tacc.utexas.edu:$LOGIN_VNC_PORT&password=$VNCP&owner=${AGAVE_JOB_OWNER}" https://designsafeci-dev.tacc.utexas.edu/webhooks/ &
curl -k --data "event_type=VNC&host=vis.tacc.utexas.edu&port=$WEBSOCKET_PORT&address=vis.tacc.utexas.edu:$LOGIN_VNC_PORT&password=$VNCP&owner=${AGAVE_JOB_OWNER}" https://www.designsafe-ci.org/webhooks/ &
# cd to the input directory and run the application with the runtime
#values passed in from the job request
cd ${workingDirectory}
CWD=${workingDirectory}

# run matlab:
# vglrun matlab

# run an xterm for the user; execution will hold here; launch matlab as well
xterm -r -ls -geometry 80x24+10+10 -title '*** Exit this window to kill your MATLAB session ***' -e 'matlab'


# job is done!

echo "Killing VGL client"
kill $VGL_PID


echo "Killing VNC server"
vncserver -kill $DISPLAY

# wait a brief moment so vncserver can clean up after itself
sleep 1

echo job $_SLURM_JOB_ID execution finished at: `date`

cd ..
rm -rf .matlab_license
rm -rf vncp.txt

#sleep to let the files get cleaned up
sleep 2

${AGAVE_JOB_CALLBACK_CLEANING_UP}

if [ ! $? ]; then
        echo "VNC exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi
