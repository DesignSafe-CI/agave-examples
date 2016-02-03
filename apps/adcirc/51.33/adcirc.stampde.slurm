#!/bin/bash                                                                                                       

#SBATCH -J adcirc_Inlet
#SBATCH -A TG-ENG150032
#SBATCH -o outputs/run.oe.%j
#SBATCH -p serial
#SBATCH -n 1
#SBATCH -t 1:00:00
#SBATCH --mail-user=mock@tacc.utexas.edu
#SBATCH --mail-type=ALL 

ibrun /work/00849/tg458981/stampede/DesignSafe/adcirc -I ./inputs -O ./outputs

