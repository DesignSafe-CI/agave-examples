#!/bin/bash

#----------------------------------------------------
# Generic SLURM script -- MPI Hello World
#
# This script requests 4 nodes and all 16 cores/node
# for a total of 64 MPI tasks.
#----------------------------------------------------
#SBATCH -J DH1            # Job name
#SBATCH -o DH1.%j.out     # stdout; %j expands to jobid
#SBATCH -e DH1.%j.err     # stderr; skip to combine stdout and stderr
#SBATCH -p vis         # queue
#SBATCH -N 2              # Number of nodes, not cores (16 cores/node)
#SBATCH -n 32             # Total number of MPI tasks (if omitted, n=N)
#SBATCH -t 00:20:00       # max time
#SBATCH -A TG-ENG150032
#SBATCH --mail-user=mock@tacc.utexas.edu
#SBATCH --mail-type=ALL

/bin/date

module load openfoam         # Load any necessary modules (these are examples)

blockMesh > blockMesh.log

decomposePar > decompose.log

ibrun pisoFoam -parallel >pisoFoam.log        # Use ibrun only for MPI codes. Don't use mpirun or srun.

reconstructPar > reconstruct.log

/bin/date
