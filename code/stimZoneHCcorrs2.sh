#!/bin/bash

home=$(pwd)
hcDir=/media/neuroimagen/Omega/addimex_conn/derivatives/final_gs_mni
controlsList=$1



while read hcontrol; do
    
    echo "Processing SUBJECT $hcontrol"
    
    for seed in $(ls ../seeds3mm/*cone_norm.nii.gz); do
        stimZ=$(basename $seed)
        stimZid=${stimZ%_cone*}
        
        echo "Extracting Time Series for $stimZ"
        
        fslmeants -i ${hcDir}/${hcontrol}_pp_scrub_gs_mni.nii.gz \
        -o timeSeries/${hcontrol}_stimZ${stimZid}.1D \
        -m ${seed}
     
        echo "Finished extracting Time Series"
        
        echo "Creating CORRelation maps for $stimZ"
        

        3dfim+ -polort 3 \
        -input ${hcDir}/${hcontrol}_pp_scrub_gs_mni.nii.gz \
        -ideal_file timeSeries/${hcontrol}_stimZ${stimZid}.1D \
        -out Correlation \
        -bucket correlationMaps/r/${hcontrol}_stimZ${stimZid}_corr.nii.gz
        
        3dcalc -a correlationMaps/r/${hcontrol}_stimZ${stimZid}_corr.nii.gz \
        -expr 'log((1+a)/(1-a))/2' \
        -prefix correlationMaps/z/${hcontrol}_stimZ${stimZid}_corrZ.nii.gz
        
              
        echo "Done with stimZone $stimZ"
        
    done
    
    echo "Done with SUBJECT $hcontrol"

done < $controlsList

echo "##DONE##"
