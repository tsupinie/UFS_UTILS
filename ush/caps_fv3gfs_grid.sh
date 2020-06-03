#!/bin/bash
#SBATCH -A TG-ATM160026
#SBATCH -J grid_create
##SBATCH -p development
#SBATCH -p normal
#SBATCH -t 02:00:00
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -o /work/01479/tsupine/fv3-hmt-2020/grid.out
#SBATCH -e /work/01479/tsupine/fv3-hmt-2020/grid.out

cd $WORK/software/UFS_UTILS/ush

export OMP_NUM_THREADS=12
export KMP_STACKSIZE=4g

export machine=stampede
export res=768
export gtype='regional'

export stretch_fac=1.5
export target_lon=-97.5
export target_lat=38.5
export refine_ratio=3
export istart_nest=123
export iend_nest=1402
export jstart_nest=331
export jend_nest=1194
export halo=3

export TMPDIR=$WORK/../fv3-hmt-2020/tmp
export out_dir=$WORK/../fv3-hmt-2020/grid

export APRUN_SFC='ibrun'

./fv3gfs_driver_grid.sh
