#!/bin/bash
#SBATCH -A TG-ATM160026
#SBATCH -J chgres_cube
#SBATCH -t 01:00:00
#SBATCH -n 48
#SBATCH -N 1
#SBATCH -o /scratch/01479/tsupine/chgres_cube.out
#SBATCH -e /scratch/01479/tsupine/chgres_cube.out
#SBATCH -p skx-dev

MEMBER=${MEMBER:-nam}

export HOMEufs=/work/01479/tsupine/stampede2/software/UFS_UTILS
export FIXfv3=${GRID_PATH:-/work/01479/tsupine/fv3-hmt-2020/grid}
cd $HOMEufs/ush

export CRES=768

export CDATE=${CDATE:-2020071700}
CYCLE=`echo $CDATE | cut -c 9-10`

INPUT_DIR=/scratch/01479/tsupine/extm

if [ $MEMBER == 'gfs' ]; then
    export INPUT_TYPE='grib2_gfs'
    INPUT_NAME=gfs193grb2
    LBC_DT=3
    fhr_width=3
elif [ $MEMBER == 'nam' ]; then
#   export INPUT_TYPE='grib2_nam'
    export INPUT_TYPE='grib2_gfs' # XXX XXX XXX
    INPUT_NAME=nam12grb2
    LBC_DT=3
    fhr_width=2
else
    export INPUT_TYPE='grib2_gfs'
    INPUT_NAME=gefs3grb2_${MEMBER}
    LBC_DT=6
    fhr_width=3
fi

fhr_fmt=`printf "%%0%dd" $fhr_width`
export COMIN=$INPUT_DIR/$INPUT_NAME/$INPUT_NAME.$CDATE
GRIB2_FILE_BASE=$INPUT_NAME.${CDATE}f
export HALO_BNDY=4
export HALO_BLEND=8
export CONVERT_NST=".false."

export VARMAP_FILE=$HOMEufs/parm/varmap_tables/GFSphys_var_map.txt
export OROG_FILES_TARGET_GRID="C${CRES}_oro_data.tile7.halo4.nc"

OUT_PATH=${OUT_PATH:-/scratch/01479/tsupine/chgres_cube/$CDATE}

#if [ -d $OUT_PATH ]; then
#    rm -rf $OUT_PATH
#fi
mkdir $OUT_PATH

FCST_LEN=${FCST_LEN:-6}
nfcst=$((FCST_LEN / LBC_DT))
nprocs_per_fcst=24

# Run the ICs first, which reduces the number of jobs running in parallel
export APRUN="ibrun -n $nprocs_per_fcst -o 0"
ifhr=`printf $fhr_fmt 0`

export GRIB2_FILE_INPUT=$GRIB2_FILE_BASE$ifhr

export DATA=$OUT_PATH/f$ifhr
mkdir $DATA

export REGIONAL=1

./chgres_cube.sh > $DATA/chgres_cube.out

ln -s f$ifhr/gfs.bndy.nc $OUT_PATH/gfs_bndy.tile7.$ifhr.nc
ln -s f${ifhr}/gfs_ctrl.nc $OUT_PATH/.
ln -s f${ifhr}/out.atm.tile1.nc $OUT_PATH/gfs_data.nc
ln -s f${ifhr}/out.sfc.tile1.nc $OUT_PATH/sfc_data.nc

# Run all the LBCs in parallel
for ((ifcst=1;ifcst<=$nfcst;ifcst++)); do
    export APRUN="ibrun -n $nprocs_per_fcst -o $(((ifcst - 1) * nprocs_per_fcst))"
    ifhr=`printf $fhr_fmt $((ifcst * LBC_DT))`

    export GRIB2_FILE_INPUT=$GRIB2_FILE_BASE$ifhr

    export DATA=$OUT_PATH/f$ifhr
    mkdir $DATA

    export REGIONAL=2

    (./chgres_cube.sh > $DATA/chgres_cube.out) &

    ln -s f$ifhr/gfs.bndy.nc $OUT_PATH/gfs_bndy.tile7.$ifhr.nc
done

wait
