set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

# Run the script with the runtime values passed in from the job request

${AGAVE_JOB_CALLBACK_RUNNING}

echo "NETCDF version"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/work/00849/tg458981/stampede/DesignSafe/apps/adcirc/51.33/netcdf.lib
#/work/00849/tg458981/stampede/DesignSafe/apps/adcirc/51.33/adcirc.bin -I ${inputDirectory} -O ./outputs >> output.eo.txt 2>&1
cd ${inputDirectory}
/work/00849/tg458981/stampede/DesignSafe/apps/adcirc/51.33/adcirc.netCDF >> output.eo.txt 2>&1
cd ..
#rm -rf outputs/PE*

if [ ! $? ]; then
        echo "ADCIRC exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi

exit 0
