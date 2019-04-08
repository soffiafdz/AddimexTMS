#!/bin/bash

for i in $(ls */*/anat/*roi.nii.gz); do 
    mkdir -p derivatives/tms_seed/${i%/sub*}; 
    mv $i derivatives/tms_seed/${i}; 
done



home=$(pwd)
std=${FSLDIR}/data/standard/MNI152_T1_2mm_brain


for i in $(ls -d derivatives/tms_seed/*/*); do
    roi=$(ls ${i}/anat/*roi.nii.gz)
    roi=$(basename $roi .nii.gz)
    new_roi=${roi}_std
    ##################################
    cd ${i}/anat
    applywarp --ref=$std --in=$roi --out=$new_roi --warp=../../../../preproc_fsl/${i#*seed/}/reg/highres2standard_warp
    cd $home
done

