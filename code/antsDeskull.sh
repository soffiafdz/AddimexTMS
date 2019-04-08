#!/bin/bash

if [ $# -eq 0 ]; then
    echo "usage "$0" <RID (007)> [...RIDS]";
    exit 0;
else
    #Variables and arguments
    home=$(pwd);
    dir=derivatives/stimZanalysis28032019/lin_correg;
    temps=/opt/ANTs/build/Templates/MICCAI2012-Multi-Atlas-Challenge-Data;
    rids=$@; #Can be several RIDS to run 
fi

brExt() {
    antsBrainExtraction.sh \
    -d 3 \
    -a $1 \
    -e $temps/T_template0.nii.gz \
    -m $temps/T_template0_BrainCerebellumProbabilityMask.nii.gz \
    -f $temps/T_template0_BrainCerebellumRegistrationMask.nii.gz \
    -o $2
}

for i in $rids; do
    cd ${dir}/${i}/ants
    echo 'Extracting brain of RID' $i
    brExt noVit2vit_sub-${i}_Warped.nii.gz noVit2vit_sub-${i}_Warped_ANTs.nii.gz
    cd $home
done
