#!/bin/bash
#Add the IntendedFor section to fieldmapping files in bids
## "IntendedFor": "func/sub-01_task-motor_bold.nii.gz"

for i in $(ls -d */*/fmap/*.json); do
    sub=${i%/*/*}
    l=$(cat $i | grep -v "^#" | wc -l)
    l2=$((l-1))
    if grep -q FM_DTI $i; then
        echo "$i is a fieldmap for DTI";
        sed -i "${l2}s|$|,\n    \"IntendedFor\": \"dwi/${sub}_dwi.nii.gz\"|" $i
    else 
        echo "$i is not a fieldmap for DTI, so it's for EPI";
        sed -i "${l2}s|$|,\n    \"IntendedFor\": \"func/${sub}_task-rest_bold.nii.gz\"|" $i
    fi
done
