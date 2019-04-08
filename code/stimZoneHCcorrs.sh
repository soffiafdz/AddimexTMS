#!/bin/bash

home=/run/media/sofdez/Omega/TMS/derivatives/stimZanalysis
hcDir=/run/media/sofdez/Omega/addimex_conn/derivatives/preproc_fsl
TsDir=${home}/timeSeries
CorrDir=${home}/correlationMaps
controlsList=$1

mkdir -p $TsDir
mkdir -p ${CorrDir}/r
mkdir -p ${CorrDir}/z

while read hcontrol; do
    
    echo "Processing SUBJECT $hcontrol"
    
    for seed in $(ls ${home}/seeds3mm/*cone_norm.nii.gz); do
        stimZ=$(basename $seed)
        stimZid=${stimZ%_cone*}
        
        echo "Extracting Time Series for $stimZ"
        
        fslmeants -i ${hcDir}/${hcontrol}/ppBold/ppBoldv2_MNI3mm_${hcontrol}.nii.gz \
        -o ${TsDir}/${hcontrol}_stimZ${stimZid} \
        -m ${seed}
        
        fslmeants -i ${hcDir}/${hcontrol}/ppBold/ppBoldv2_woGSR_MNI3mm_${hcontrol}.nii.gz \
        -o ${TsDir}/${hcontrol}_stimZ${stimZid}_woGSR \
        -m ${seed}

        echo "Finished extracting Time Series"
        
        echo "Creating CORRelation maps for $stimZ"
        
        3dfim+ -polort 3 \
        -input ${hcDir}/${hcontrol}/ppBold/ppBoldv2_MNI3mm_${hcontrol}.nii.gz \
        -ideal_file ${TsDir}/${hcontrol}_stimZ${stimZid} \
        -out Correlation \
        -bucket ${CorrDir}/r/${hcontrol}_stimZ${stimZid}_corr.nii.gz
        
        3dcalc -a ${CorrDir}/r/${hcontrol}_stimZ${stimZid}_corr.nii.gz \
        -expr 'log((1+a)/(1-a))/2' \
        -prefix ${CorrDir}/z/${hcontrol}_stimZ${stimZid}_corrZ.nii.gz
        
        
        3dfim+ -polort 3 \
        -input ${hcDir}/${hcontrol}/ppBold/ppBoldv2_woGSR_MNI3mm_${hcontrol}.nii.gz \
        -ideal_file ${TsDir}/${hcontrol}_stimZ${stimZid}_woGSR \
        -out Correlation \
        -bucket ${CorrDir}/r/${hcontrol}_stimZ${stimZid}_woGSR_corr.nii.gz
        
        3dcalc -a ${CorrDir}/r/${hcontrol}_stimZ${stimZid}_woGSR_corr.nii.gz \
        -expr 'log((1+a)/(1-a))/2' \
        -prefix ${CorrDir}/z/${hcontrol}_stimZ${stimZid}_woGSR_corrZ.nii.gz
        echo "Done with stimZone $stimZ"
        
    done
    
    echo "Done with SUBJECT $hcontrol"

done < $controlsList

echo "##DONE##"
        
        
        
        
