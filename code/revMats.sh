#!/bin/bash

#mat #net
#Networks lenghts
aud=14; cereb=5; co_tc=15; d_att=12; dmn=59; fp_tc=26; mem_r=6; sal=19; sm_h=31; sm_m=6; subc=14; uncert=29; v_att=10; vis=32; wb=265
if [[ -z $errors ]]; then errors=0 ; fi
for i in $(ls -d ${1}/*_r.csv); do
    n=$(awk '{n+=1} END {print n}' $i)
    mat1=$(basename $i)
    netn=${mat1#*_matrix_}
    netn=${netn%_*}
    ln=${!netn}
    echo "Reviewing $mat1 dimensions"
    if [[ $n != $ln ]]; then
        echo "Matrix $mat1 has the wrong dimensions: $n ; instead of $ln "
        errors=$((errors+1))
    fi
done
echo "The number of misnumbered matrices is $errors"
