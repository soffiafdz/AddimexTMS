#!/bin/bash
 
home=$(pwd)
mni=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz

for i in $(ls -d *); do
	bname=$(basename $i .nii.gz)
	name=${bname#*_*_}
	rses=${bname%_*}
	rid=${rses%_*}
	ses=${rses#*_}
	natSpace=${home}/[]/preproc_fsl/sub-${i}/ses-${ses}/reg/structural_head.nii.gz
	############################
	WarpImageMultiTransform 3 $i ${bname}_MNI2mm.nii.gz -R $mni ../ants/${rid}/${rses}_MNI2mm_Warp.nii.gz ../ants/${rid}/${rses}_MNI2mm_Affine.txt
done





