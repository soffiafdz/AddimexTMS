#!/bin/bash


inDir=$1
outDir=$2
seedsDir=$3
SubsList=$4

usg="Usage: $0 <inDir: directory with the preprocessed BOLD images> \n \
<outDir: directory to output files> \n \
<seedsDir: directory with seeds \n \
<IDSfile: CSV file with sub (and session)>"

if [[ $# -lt 4 ]]; then
	echo $usg;
	exit 0;
else
    while read subID; do
        echo "Processing SUBJECT $subID"
        for seed in $(ls ${seedsDir}/*mniConeNorm.nii.gz); do
            stimZ=$(basename $seed)
            stimZid=${stimZ%mniCone*}

            for gs in gs0 gs1; do
                echo "Extracting Time Series for $stimZ (${gs})"
                mkdir -p ${outDir}/timeSeries/${gs}
                #FSL
                fslmeants -i ${inDir}/${subID}_pp_scrub_${gs}_mni.nii.gz \
                -o ${outDir}/timeSeries/${gs}/${subID}_stimZ${stimZid}_${gs}.1D \
                -m ${seed}

                echo "Finished extracting Time Series"

                echo "Creating CORRelation maps for $stimZ (${gs})"
                mkdir -p ${outDir}/correlationMaps/r
                mkdir -p ${outDir}/correlationMaps/z
                #AFNI
                3dfim+ -polort 3 \
                -input ${inDir}/${subID}_pp_scrub_gs_mni.nii.gz \
                -ideal_file ${outDir}/timeSeries/${subID}_stimZ${stimZid}.1D \
                -out Correlation \
                -bucket ${outDir}/correlationMaps/r/${subID}_stimZ${stimZid}_corr.nii.gz
                #AFNI
                3dcalc -a ${outDir}/correlationMaps/r/${subID}_stimZ${stimZid}_corr.nii.gz \
                -expr 'log((1+a)/(1-a))/2' \
                -prefix ${outDir}/correlationMaps/z/${subID}_stimZ${stimZid}_corrZ.nii.gz
            done
            echo "Done with stimZone $stimZ"
        done
        echo "Done with SUBJECT $subID"
    done < $controlsList
fi
echo "## DONE ##"
