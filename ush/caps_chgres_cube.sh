#!/bin/bash
#SBATCH -A TG-ATM160026
#SBATCH -J chgres_cube
#SBATCH -t 01:00:00
#SBATCH -n 48
#SBATCH -N 1
#SBATCH -o /scratch/01479/tsupine/chgres_cube.out
#SBATCH -e /scratch/01479/tsupine/chgres_cube.out
#SBATCH -p skx-dev

MEMBER=${MEMBER:-gfs}

export HOMEufs=/work/01479/tsupine/stampede2/software/UFS_UTILS
export FIXfv3=${GRID_PATH:-/work/01479/tsupine/fv3-hmt-2020/grid}
cd $HOMEufs/ush

export CRES=768

export CDATE=${CDATE:-2020042800}
CYCLE=`echo $CDATE | cut -c 9-10`

export INPUT_TYPE='grib2'
export CONVERT_NST=".false."
if [ $MEMBER == 'gfs' ]; then
    export COMIN=/scratch/01479/tsupine/extm/gfs/gfs.$CDATE
    export GRIB2_FILE_BASE=gfs.t${CYCLE}z.pgrb2.0p25.f0
    LBC_DT=6
elif [ $MEMBER == 'nam' ]; then
    export COMIN=/scratch/01479/tsupine/extm/nam12grb2/nam12grb2.$CDATE
    export GRIB2_FILE_BASE=nam12grb2.${CDATE}f
    LBC_DT=3
else
    export COMIN=/scratch/01479/tsupine/extm/gefs/gefs.$CDATE
    export GRIB2_FILE_BASE=$MEMBER.t${CYCLE}z.pgrb2f
    LBC_DT=6
fi
    
export HALO_BNDY=4
export HALO_BLEND=8

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

for ((ifcst=0;ifcst<=$nfcst;ifcst++)); do
    export APRUN="ibrun -n $nprocs_per_fcst -o $((ifcst * nprocs_per_fcst))"
    ifhr=`printf "%02d" $((ifcst * LBC_DT))`

    export GRIB2_FILE_INPUT=$GRIB2_FILE_BASE$ifhr

    export DATA=$OUT_PATH/f$ifhr
    mkdir $DATA

    if [ $ifhr == 00 ]; then
        export REGIONAL=1
    else
        export REGIONAL=2
    fi

    (./chgres_cube.sh > $DATA/chgres_cube.out) &

    ln -s f$ifhr/gfs.bndy.nc $OUT_PATH/gfs_bndy.tile7.0$ifhr.nc
    if [ $ifhr == 00 ]; then
        ln -s f${ifhr}/gfs_ctrl.nc $OUT_PATH/.
        ln -s f${ifhr}/out.atm.tile1.nc $OUT_PATH/gfs_data.nc
        ln -s f${ifhr}/out.sfc.tile1.nc $OUT_PATH/sfc_data.nc
    fi
done

wait
