#!/bin/bash
 
home=$(pwd)
std2=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
dir=derivatives/stimZanalysis/ants201119
rids=$@

session() {
    rid10=10#${1}
    if (( $rid10 >= 10#022 )); then
        sess=t0
    else 
        case $1 in 
            002|004) 
                sess=t4;;
            008)
                sess=t5;;
            020)
                sess=t2;;
            021)
                sess=t1;;
            036)
                sess=t1;;
            *)
                echo 'ERROR: RID not found';
                exit 0; 
        esac
    fi
    echo 'RID' $1 'Session' $sess;
}

for i in $rids; do
    if [ -e ${dir}/${i}/*MNI2mm.nii.gz ]; then
        echo "$i is normalized already, moving on"
    else
        mkdir -p derivatives/ants/${i}
        cd ${dir}/${i}
        session $i
        t1w=derivatives/preproc_fsl/sub-${i}/ses-${sess}/reg/structural_head.nii.gz
        # ANTS
        ANTS 3 -m CC[$std2,$t1w,1,4] -i 50x20x10 -o ${i}_${sess}_MNI2mm_ -t SyN[0.1,3,0]
        # WarpImage
        WarpImageMultiTransform 3 $t1w ${i}_${sess}_MNI2mm.nii.gz -R $std2 ${i}_${sess}_MNI2mm_Warp.nii.gz ${i}_${sess}_MNI2mm_Affine.txt
        cd $home
    fi
done

