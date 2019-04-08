#!/bin/bash

if [ $# -eq 0 ]; then
    echo "usage: "$0" <RID (005)> [RIDS...]";
    exit 0;
else
    #Variables and arguments
    home=$(pwd);
    dir=derivatives/stimZanalysis/lin_correg;
    rids=$@; #Can be several RIDS to run 
fi

#Function to extract the vit and noVit sessions of the RIDS
session() {
    rid10=10#${1};

    if (( rid10 >= 10#022 & rid10 < 10#035 )); then
        vit="t0"
    else 
        case $1 in 
            002|004) 
                vit="t4";;
            008)
                vit="t5";;
            020)
                vit="t2";;
            021)
                vit="t1";;
            036)
                vit="t1";;
            037)
                vit="t0";;
            *)
                echo 'ERROR: RID not found';
                exit 0; 
        esac
    fi
    if [ $vit == "t0" ]; then
        noVit="t1"
    else
        noVit="t0"
    fi
    echo 'RID' $1 'Vitamin image' $vit 'Normal image' $noVit;
}

regis() { #vit #noVit #Warped
    antsRegistration \
        --dimensionality 3 \
        --float 0 \
        --output [noVit2vit_sub-${i}_, \
        noVit2vit_sub-${i}_${3}.nii.gz] \
        --interpolation Linear \
        --use-histogram-matching 0 \
        --initial-moving-transform [$1,$2,1] \
        --transform Rigid[0.1] \
        --metric MI[$1,$2,1,32,Regular,0.25] \
        --convergence [1000x500x250x100,1e-6,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox \
        --transform Affine[0.1] \
        --metric MI[$1,$2,1,32,Regular,0.25] \
        --convergence [1000x500x250x100,1e-6,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 3x2x1x0vox
}
for i in $rids; do
    if [ -e ${dir}/${i}/*MNI2mm.nii.gz ]; then
        echo "$i is normalized already, moving on"
    else
        #Setting up vitamin sessions
        session $i
        vit_hd=${home}/derivatives/preproc_fsl/sub-${i}/ses-${vit}/reg/structural_head.nii.gz
        vit_br=${home}/derivatives/preproc_fsl/sub-${i}/ses-${vit}/reg/structural_brain.nii.gz
        noVit_hd=${home}/derivatives/preproc_fsl/sub-${i}/ses-${noVit}/reg/structural_head.nii.gz
        noVit_br=${home}/derivatives/preproc_fsl/sub-${i}/ses-${noVit}/reg/structural_brain.nii.gz

	#Creatind directories
        mkdir -p ${dir}/${i}/vit
        mkdir -p ${dir}/${i}/noVit
        mkdir -p ${dir}/${i}/ants

	#Copying files
        cp $vit_hd ${dir}/${i}/vit
        cp $vit_br ${dir}/${i}/vit
        cp $noVit_hd ${dir}/${i}/noVit
        cp $noVit_br ${dir}/${i}/noVit

	#ANTS
        cd ${dir}/${i}/ants
        regis $vit_hd $noVit_hd Warped
        regis $vit_br $noVit_br Warped_brain
        cd $home
    fi
done

