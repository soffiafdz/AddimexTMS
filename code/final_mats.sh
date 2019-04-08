#!/bin/bash

review_mats() { #mat
    #Networks lenghts
    aud=14; cereb=5; co_tc=15; d_att=12; dmn=59; fp_tc=26; mem_r=6; sal=19; sm_h=31; sm_m=6; subc=14; uncert=29; v_att=10; vis=32; wb=265
    n=$(awk '{n+=1} END {print n}' $1)
    x=$(basename $1)
    y=${x#*_matrix_}
    netn=${y%_*}
    ln=${!netn}
    echo $netn
    if [[ $n != $ln ]]; then
        echo "Matrix $x has the wrong dimensions: $n; instead of $ln "
        echo "ABORTING... Check integrity of matrices."
        exit 0;
    fi
}


rem1l() {
    sed -i '1d' $1;
    sed -i 's/,/\t/g' $1;
}

#arg1 -> derivatives/graphs/matrices/power_141118/pos/

#derivatives/graphs/matrices/power_141118/pos/wb/hc/sub-160_matrix_wb_r.csv

if [ $# -lt 1 ]; then 
    echo "Usage: $0 <mats_dir (derivatives/graphs/matrices/power_141118/pos/)>"
    exit 0;
fi

for i in $(ls -d ${1}*/*/*r.csv); do
    basedir=$(pwd)
    res1=${i#${1}}
    dir=${res1%/*} #wb/hc
    gr=${dir#*/}
    outdir1=derivatives/graphs/matrices/pwr_final/${dir}
    outdir2=${outdir1%/$gr}
    outdir2=${outdir2}/all	
    matname=$(basename $i)
    sub=${matname%_ses*_matrix*}
    subn=${sub#sub-}
    review_mats $i
    echo "$matname"
    excl $subn
    if [[ $exclude == yes ]]; then 
        exclude=no
        echo "...EXCLUDED..."
        continue 
    fi
    mkdir -p $outdir1
    mkdir -p $outdir2
    cp $i $outdir1
    cp $i $outdir2
    echo "...COPIED..."
    rem1l ${outdir1}/$matname
    rem1l ${outdir2}/$matname
    echo "...READY..."
done
