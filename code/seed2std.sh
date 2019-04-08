#!/bin/bash
##Run from directory of seeds "Seeds2" 
home=$(pwd)
std3=MNI152_T1_2mm_brain.nii.gz
stdMask3=MNI152_T1_3mm_brain_mask.nii.gz
std2=MNI152_T1_3mm_brain.nii.gz
stdMask2=MNI152_T1_2mm_brain_mask.nii.gz

session() {
    rid10=10#${1}
    if (( $rid10 >= 022 )); then
        sess=ses-t0
    else 
        case $1 in 
            002|004) 
                sess=ses-t4;;
            008)
                sess=ses-t5;;
            020)
                sess=ses-t2;;
            021)
                sess=ses-t1;;
            *)
                echo 'ERROR: RID not found';
                exit 0; 
        esac
    fi
    echo 'RID' $1 'Session' $sess;
}

for i in $(ls *Stim12*); do
    out=$(basename $i .nii.gz)
    out=${out}std
    rid=${i%seed*}
    session $rid
    ##################################    
    applywarp -i $i -o seedMNI12mm/${out} -r ${FSLDIR}/data/standard/${std} -w ../preproc_fsl/sub-${rid}/${sess}/reg/highres2standard_warp
    fslmaths seedMNI12mm/${out} -mul $stdMask -bin seedMNI12mm/${out}_mskd
    cd $home
done

