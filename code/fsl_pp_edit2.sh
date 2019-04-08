#!/bin/bash

##Example of path in bids format
##/run/media/sofdez/Alpha/TMS/bids/sub-0*/ses-t*/[func,anat]/*.nii.gz

usg="Usage: $0 <sub (001 002 ...)> <sess (t0 ... t14)> Note: run this script from the bids directory"
sub=sub-${1};
ses=ses-${2};
root=./${sub}/${ses}

if [ $# -lt 2 ]; then
    echo $usg;
    exit 0;
elif [ ! -e ./${sub} ]; then
    echo "can't find that subject in the bids directory";
    exit 0;
elif [ ! -e $root ]; then
    echo "can't find that session in the ${sub} directory";
    exit 0;
else
    echo "Running preprocessing script of ${sub}, ${ses}"
    #Constants and variables
    bold=${root}/func/${sub}_${ses}_task-rest_bold.nii.gz;
    pre_str=${root}/anat/${sub}_${ses}_T1w.nii.gz;
    bold_bn=$(basename $bold .nii.gz); 
    outdir=derivatives/preproc_fsl/${sub}/${ses};

    
    #Extracting and saving TR
    TR=$(${FSLDIR}/bin/fslval $bold pixdim4);

   
    nslices=$(${FSLDIR}/bin/fslval $bold dim3);
   

   
    highres_head=${reg_dir}/${str_bn}_head.nii.gz;
    highres_brain=${reg_dir}/${str_bn}_brain.nii.gz;
    meanfunc=${outdir}/meanfunc.nii.gz;
    mni152_brain=${FSLDIR}/data/standard/MNI152_T1_2mm_brain; 
    mni152_head=${FSLDIR}/data/standard/MNI152_T1_2mm; 
    standard_mask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil; 

  
    stats_dir=${outdir}/stats;
    QMov_dir=${outdir}/QMov;
    
    conf_dir=${outdir}/conf;
    mkdir -p ${conf_dir} ;
    
    echo "################################################";
    echo "Apply Transformations and Temporal Filtering";
    echo "################################################";

    #Directories and constants
    outbn=ppBoldv2;
    hpf=0.01;
    lpf=0.08;

    ppBold_dir=${outdir}/ppBold;

    hp_sigma=`echo "scale=2 ;(1/${hpf})/2.35/${TR}" | bc`; # In volumes for fslmaths
    lp_sigma=`echo "scale=2 ;(1/${lpf})/2.35/${TR}" | bc`; # In volumes for fslmaths

    echo "Projecting to Standard space (MNI, 3mm)";
    for input in ${stats_dir}/res4d ${stats_dir}/res4d_woGSR; do
        ${FSLDIR}/bin/applywarp --ref=/media/brain/Omega/MNI152_T1_3mm.nii.gz --in=${input} --warp=${outdir}/reg/highres2standard_warp.nii.gz --out=${input}_MNI3mm --premat=${outdir}/reg/meanfunc2highres.mat --interp=trilinear;
    done


    echo "Bandpass Temporal Filtering to MNI files";


    for i in $(ls ${stats_dir}/*MNI*gz);do 
        en=$(basename $i .nii.gz | cut -d _ -f 2-);
        ${FSLDIR}/bin/fslhd -x $i > ${stats_dir}/tmphdr.txt;
        sed -n "s/dt =.*/dt = \'${TR}\'/" ${stats_dir}/tmphdr.txt;
        ${FSLDIR}/bin/fslcreatehd ${stats_dir}/tmphdr.txt $i;

        ${FSLDIR}/bin/fslmaths $i -bptf $hp_sigma $lp_sigma ${ppBold_dir}/${outbn}_${en}_${sub}_${ses};
    done

    rm ${stats_dir}/tmphdr.txt;
    echo "################################################";
    echo "Finished with preprocessing of ${sub}, ${ses}"; 
    echo "################################################";
fi

















