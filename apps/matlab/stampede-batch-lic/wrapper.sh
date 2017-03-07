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

# set memory limits to 95% of total memory to prevent node death
NODE_MEMORY=`free -k | grep ^Mem: | awk '{ print $2; }'`
NODE_MEMORY_LIMIT=`echo "0.95 * $NODE_MEMORY / 1" | bc`
ulimit -v $NODE_MEMORY_LIMIT -m $NODE_MEMORY_LIMIT
echo "memory limit set to $NODE_MEMORY_LIMIT kilobytes"

# set wayness, used for ibrun
WAYNESS=`echo $PE | perl -pe 's/([0-9]+)way/\1/;'`
echo "set wayness to $WAYNESS"

#agave callback to let it know the job is running
${AGAVE_JOB_CALLBACK_RUNNING}

cd ${workingDirectory}
CWD=${workingDirectory}

echo "Directory is `pwd`"

ls -al

# run matlab:
matlab -nosplash -nodesktop < ${inputScript} >> matlab_output.eo.txt 2>&1

# job is done!

echo job $_SLURM_JOB_ID execution finished at: `date`

cd ..
rm -rf .matlab_license
rm -rf vncp.txt

pwd
ls -alrt

#sleep to let the files get cleaned up
sleep 2

${AGAVE_JOB_CALLBACK_CLEANING_UP}

if [ ! $? ]; then
        echo "MATLAB exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi

exit 0
