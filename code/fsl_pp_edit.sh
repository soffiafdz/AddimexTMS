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

    #####################################################
    #Logging inputs
    mkdir -p ${outdir};

    echo "##################################";
    echo "Inputs: ";
    echo "Bold: " ${bold};
    echo "Structural: "${pre_str};
    echo "##################################";

    echo "Inputs: " >> ${outdir}/inputs.txt;
    echo " " >> ${outdir}/inputs.txt;
    echo "Bold: " ${bold} >> ${outdir}/inputs.txt;
    echo "Structural: " ${pre_str} >> ${outdir}/inputs.txt;
    
    #####################################################

    echo "##################################";
    echo "Preprocessing 4D_bold data";
    echo "##################################";

    #Extracting and saving TR
    TR=$(${FSLDIR}/bin/fslval $bold pixdim4);

    echo "Example volume of functional data";
    ${FSLDIR}/bin/fslroi $bold ${outdir}/${bold_bn}_example_func 0 1;

    echo "Slice timing correction";
    nslices=$(${FSLDIR}/bin/fslval $bold dim3);
    ${FSLDIR}/bin/slicetimer -i $bold -o ${outdir}/prefiltered_func_data_st -r ${TR} --odd;

    echo "Motion correction";
    ${FSLDIR}/bin/mcflirt -in ${outdir}/prefiltered_func_data_st -out ${outdir}/prefiltered_func_data_mcf -plots -refvol 0 -verbose 0;

    echo "Brain Extraction";
    ${FSLDIR}/bin/fslmaths ${outdir}/prefiltered_func_data_mcf -Tmean ${outdir}/pmeanfunc;
    ${FSLDIR}/bin/bet2 ${outdir}/pmeanfunc ${outdir}/mask -f 0.35 -n -m;
    ${FSLDIR}/bin/immv ${outdir}/mask_mask ${outdir}/mask;
    ${FSLDIR}/bin/fslmaths ${outdir}/prefiltered_func_data_mcf -mas ${outdir}/mask ${outdir}/prefiltered_func_data_bet;

    echo "Filtered func data";
    ${FSLDIR}/bin/fslmaths ${outdir}/prefiltered_func_data_bet ${outdir}/filtered_func_data;
    ${FSLDIR}/bin/fslmaths ${outdir}/filtered_func_data -Tmean ${outdir}/meanfunc;

    #Remove pre-filtered data
    rm -rf ${outdir}/prefiltered_func_data_*.nii* ${outdir}/pmeanfunc.*;
    
    #####################################################

    echo "##################################";
    echo "Preprocessing Structural data";
    echo "##################################";

    #Reorient to standard template
    ${FSLDIR}/bin/fslreorient2std $pre_str ${outdir}/structural.nii.gz;

    #Constants and directories
    str=${outdir}/structural.nii.gz;
    str_bn=$(basename $str .nii.gz);
    reg_dir=${outdir}/reg;

    mkdir -p $reg_dir;

    echo "Brain extraction";
    ${FSLDIR}/bin/bet $str ${reg_dir}/${str_bn}_brain -B -f 0.35 -g 0
    ${FSLDIR}/bin/fast -t 1 -n 3 -H 0.1 -I 4 -l 20 -B -g -o ${reg_dir}/${str_bn}_brain ${reg_dir}/${str_bn}_brain
    ${FSLDIR}/bin/immv ${reg_dir}/${str_bn}_brain_restore.nii.gz ${reg_dir}/${str_bn}_brain.nii.gz

    echo "##################################";
    echo "Registration";
    echo "##################################";

    echo "Registration... Linear";
    #Constants and directories
    cp $str ${reg_dir}/${str_bn}_head.nii.gz;
    rm $str;
    highres_head=${reg_dir}/${str_bn}_head.nii.gz;
    highres_brain=${reg_dir}/${str_bn}_brain.nii.gz;
    meanfunc=${outdir}/meanfunc.nii.gz;
    mni152_brain=${FSLDIR}/data/standard/MNI152_T1_2mm_brain; 
    mni152_head=${FSLDIR}/data/standard/MNI152_T1_2mm; 
    standard_mask=${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil; 

    echo "Registration... meanfunc to highres";
    ${FSLDIR}/bin/flirt -ref $highres_brain -in $meanfunc -out ${reg_dir}/meanfunc2highres -omat ${reg_dir}/meanfunc2highres.mat -cost corratio -dof 6 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear;

    echo "Registration... inverse: highres to meanfunc";
    ${FSLDIR}/bin/convert_xfm -inverse -omat ${reg_dir}/highres2meanfunc.mat ${reg_dir}/meanfunc2highres.mat;

    echo "Registration... highres to standard";
    ${FSLDIR}/bin/flirt -ref $mni152_brain -in $highres_brain -out ${reg_dir}/highres2standard -omat ${reg_dir}/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear;

    echo "Registration... inverse: standard to highres";
    ${FSLDIR}/bin/convert_xfm -inverse -omat ${reg_dir}/standard2highres.mat ${reg_dir}/highres2standard.mat;

    echo "Registration... meanfunc to standard";
    ${FSLDIR}/bin/convert_xfm -omat ${reg_dir}/meanfunc2standard.mat -concat ${reg_dir}/highres2standard.mat ${reg_dir}/meanfunc2highres.mat;

    echo "Registration... inverse: standard to meanfunc";
    ${FSLDIR}/bin/convert_xfm -omat ${reg_dir}/standard2meanfunc.mat -inverse ${reg_dir}/meanfunc2standard.mat;


    echo "Registration... Non-linear";
    echo "Registration... highres to standard";
    ${FSLDIR}/bin/fnirt --in=${highres_head} --aff=${reg_dir}/highres2standard.mat --cout=${reg_dir}/highres2standard_warp --iout=${reg_dir}/highres2standard_fnirt --jout=${reg_dir}/highres2standard_jac --config=T1_2_MNI152_2mm --ref=${mni152_head} --refmask=${standard_mask} --warpres=10,10,10;

    echo "Registration... apply transformations to meanfunc";
    ${FSLDIR}/bin/applywarp --ref=${mni152_brain} --in=${meanfunc} --out=${reg_dir}/meanfunc2standard_w --warp=${reg_dir}/highres2standard_warp --premat=${reg_dir}/meanfunc2highres.mat;

    echo "Registration... apply transformations to highres";
    ${FSLDIR}/bin/applywarp --ref=${mni152_brain} --in=${highres_brain} --out=${reg_dir}/highres2standard_w --warp=${reg_dir}/highres2standard_warp;

    echo "Checking registration and graphing it";

    #Check registration figures
    font=/usr/share/fonts/TTF/DejaVuSans-Bold.ttf;
    ${FSLDIR}/bin/slicer ${reg_dir}/meanfunc2highres.nii.gz ${highres_brain} -a ${reg_dir}/func_highres.png;
    ${FSLDIR}/bin/slicer -e 0.1 ${reg_dir}/highres2standard_w.nii.gz ${mni152_brain}  -a ${reg_dir}/highres_standard.png;
    ${FSLDIR}/bin/slicer -e 0.1 ${reg_dir}/meanfunc2standard_w ${mni152_brain} -a ${reg_dir}/func_standard.png;

    #Montage of the figures
    montage -quality 60 -font ${font} -fill white -label '%f' ${reg_dir}/func_highres.png ${reg_dir}/highres_standard.png ${reg_dir}/func_standard.png -tile 1x3 -background '#000000' -geometry '480' ${reg_dir}/checkreg_${bold_bn}.jpg;

    #Removing preliminary figures
    rm ${reg_dir}/*.png;

    echo "################################################";
    echo "FD estimation";
    echo "################################################";
    #Constants and directories
    FDthreshold=.5;
    stats_dir=${outdir}/stats;
    QMov_dir=${outdir}/QMov;
    mkdir -p $stats_dir; 
    mkdir -p $QMov_dir;
    echo $FDthreshold > ${QMov_dir}/FDthreshold.par;

    echo "Calculating relative displacements";
    awk '{print $4}' ${outdir}/prefiltered_func_data_mcf.par | awk '{print $0-p}{p=$0}' | awk '{ print ($1 >= 0) ? $1 : 0 - $1}' > ${outdir}/preFD_mm_04.txt;
    awk '{print $5}' ${outdir}/prefiltered_func_data_mcf.par | awk '{print $0-p}{p=$0}' | awk '{ print ($1 >= 0) ? $1 : 0 - $1}' > ${outdir}/preFD_mm_05.txt;
    awk '{print $6}' ${outdir}/prefiltered_func_data_mcf.par | awk '{print $0-p}{p=$0}' | awk '{ print ($1 >= 0) ? $1 : 0 - $1}' > ${outdir}/preFD_mm_06.txt;

    paste ${outdir}/preFD_mm_04.txt ${outdir}/preFD_mm_05.txt ${outdir}/preFD_mm_06.txt | awk '{print sqrt($1*$1+$2*$2+$3*$3)}' > ${QMov_dir}/FD_RMSdisp.txt;

    rm ${outdir}/preFD_mm*;

    awk -v var="$FDthreshold" '{if ($1 > var ) print 1; else print 0}' ${QMov_dir}/FD_RMSdisp.txt > ${QMov_dir}/FD_peaks.txt;

    cat ${QMov_dir}/FD_peaks.txt | grep 1 | wc -l > ${QMov_dir}/NVols_FDpeaks.txt;

    echo "Making PNG image of movement";
    awk -v var="$FDthreshold" '{print $1*0+var}' ${QMov_dir}/FD_RMSdisp.txt > ${QMov_dir}/thresh.txt;
    paste ${QMov_dir}/FD_RMSdisp.txt ${QMov_dir}/thresh.txt > ${QMov_dir}/FD_RMSdisp_thresh.txt;
    rm -f ${QMov_dir}/thresh.txt;


    ${FSLDIR}/bin/fsl_tsplot -i ${outdir}/prefiltered_func_data_mcf.par -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o ${QMov_dir}/rot.png;
    ${FSLDIR}/bin/fsl_tsplot -i ${outdir}/prefiltered_func_data_mcf.par -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o ${QMov_dir}/trans.png;
    ${FSLDIR}/bin/fsl_tsplot -i ${QMov_dir}/FD_RMSdisp_thresh.txt -t 'Framewise Displacement relative RMS DisplacementsOnly (mm)' -u 1 --start=1 --finish=2 -a FD,threshold -w 640 -h 144 -o ${QMov_dir}/FDrelRMSd.png;

    montage ${QMov_dir}/FDrelRMSd.png ${QMov_dir}/rot.png ${QMov_dir}/trans.png -tile x3 -geometry 640x144+2+2 ${QMov_dir}/montage.png;

    #Mean and standard deviation
    echo -e "\t\tMean\t\tStDev" > ${QMov_dir}/FDrelRMSd_mean_std.txt;
    awk '{ if ($1 > 0) print $1}' ${QMov_dir}/FD_RMSdisp_thresh.txt | awk '{delta = $1 - avg; avg += delta / NR; mean2 += delta * ($1 - avg); } END { print "FD \t\t"avg"\t\t"sqrt(mean2 / NR); }' >> ${QMov_dir}/FDrelRMSd_mean_std.txt;

    echo "############################################";
    echo "Extracting confounding variables from data";
    echo "############################################";

    #Constants and directories
    conf_dir=${outdir}/conf;
    mkdir -p ${conf_dir} ;
    rm -f ${conf_dir}/*_func*;

    echo "Masks for white matter and CSF, based on segmentation";
    ${FSLDIR}/bin/fslmaths ${reg_dir}/${str_bn}_brain_seg_0 -thr 0.99 -bin -ero ${conf_dir}/sub_CSF;
    ${FSLDIR}/bin/fslmaths ${reg_dir}/${str_bn}_brain_seg_2 -thr 0.99 -bin -ero ${conf_dir}/sub_WM;
    ${FSLDIR}/bin/fslmaths ${conf_dir}/sub_CSF -add ${conf_dir}/sub_WM ${conf_dir}/sub_CSFWM;

    echo "Taking segmentation masks to functional space";
    for i in $(ls ${conf_dir}/sub_*); do 
        j=$(basename $i .nii.gz); ${FSLDIR}/bin/flirt -in ${i} -applyxfm -init ${reg_dir}/highres2meanfunc.mat -out ${conf_dir}/${j}_func -paddingsize 0.0 -interp nearestneighbour -ref ${outdir}/meanfunc; 
    done;

    echo "Extracting Global signal";
    ${FSLDIR}/bin/fslmeants -i ${outdir}/filtered_func_data -o ${conf_dir}/Global.txt -m ${outdir}/mask;

    echo "Extracting CSF signal";
    ${FSLDIR}/bin/fslmeants -i ${outdir}/filtered_func_data -o ${conf_dir}/CSF.txt -m ${conf_dir}/sub_CSF_func;

    echo "Extracting WM signal";
    ${FSLDIR}/bin/fslmeants -i ${outdir}/filtered_func_data -o ${conf_dir}/WM.txt -m ${conf_dir}/sub_WM_func;

    echo "aCompCor: 5 components";
    ${FSLDIR}/bin/fslmeants -i ${outdir}/filtered_func_data -o ${conf_dir}/aCompCor.txt -m ${conf_dir}/sub_CSFWM_func --eig --order=5;

    rm -f ${outdir}/design.mat;
    ntpoints=$(wc -l < ${conf_dir}/WM.txt);

    #paste columns
    paste -d " " ${conf_dir}/Global.txt ${conf_dir}/CSF.txt ${conf_dir}/WM.txt ${outdir}/prefiltered_func_data_mcf.par > ${conf_dir}/design_prev.mat;
    paste -d " " ${conf_dir}/CSF.txt ${conf_dir}/WM.txt ${outdir}/prefiltered_func_data_mcf.par > ${conf_dir}/design_prev_woGSR.mat;


    echo "Making a file with the derivates and squares of confounding variables";
    Rscript --vanilla ./code/dp2.R ${conf_dir}/design_prev.mat ${conf_dir}/dp2_design_prev.mat;
    Rscript --vanilla ./code/dp2.R ${conf_dir}/design_prev_woGSR.mat ${conf_dir}/dp2_design_prev_woGSR.mat;

    echo "Creating the design matrix";
    npeaks=$(cat ${QMov_dir}/NVols_FDpeaks.txt);
    if [ $npeaks -gt 0 ]; then
        #Generate columbs of peaks of FD
        Rscript --vanilla ./code/colpeaks.R ${QMov_dir}/FD_peaks.txt ${QMov_dir}/FD_confvars.txt;
        nwaves=`echo "41+$npeaks" | bc`;
        echo "/NumWaves $nwaves" > ${conf_dir}/design.mat;
        echo "/NumPoints $ntpoints" >> ${conf_dir}/design.mat;
        echo "" >> ${conf_dir}/design.mat;
        paste -d "\t" ${conf_dir}/dp2_design_prev.mat ${conf_dir}/aCompCor.txt ${QMov_dir}/FD_confvars.txt >> ${conf_dir}/design.mat;
        #noGSR
        echo "/NumWaves 37+$npeaks" > ${conf_dir}/design_woGSR.mat;
        echo "/NumPoints $ntpoints" >> ${conf_dir}/design_woGSR.mat;
        echo "" >> ${conf_dir}/design_woGSR.mat;
        paste -d "\t" ${conf_dir}/dp2_design_prev_woGSR.mat ${conf_dir}/aCompCor.txt ${QMov_dir}/FD_confvars.txt >> ${conf_dir}/design_woGSR.mat;	
    else
        echo "/NumWaves 41" > ${conf_dir}/design.mat;
        echo "/NumPoints $ntpoints" >> ${conf_dir}/design.mat;
        echo "" >> ${conf_dir}/design.mat;
        paste -d "\t" ${conf_dir}/dp2_design_prev.mat ${conf_dir}/aCompCor.txt >> ${conf_dir}/design.mat;
        #noGSR
        echo "/NumWaves 37" > ${conf_dir}/design_woGSR.mat;
        echo "/NumPoints $ntpoints" >> ${conf_dir}/design_woGSR.mat;
        echo "" >> ${conf_dir}/design_woGSR.mat;
        paste -d "\t" ${conf_dir}/dp2_design_prev_woGSR.mat ${conf_dir}/aCompCor.txt >> ${conf_dir}/design_woGSR.mat;	
    fi

    echo "General Linear Model - Global signal";

    ${FSLDIR}/bin/fsl_glm -i ${outdir}/filtered_func_data.nii.gz -m ${outdir}/mask.nii.gz -d ${conf_dir}/design.mat --demean --out_res=${stats_dir}/res4d.nii.gz;

    mean_bold=$(${FSLDIR}/bin/fslstats ${outdir}/filtered_func_data -k ${outdir}/mask -M);
    echo $mean_bold >> ${stats_dir}/mean_filteredfunc;

    echo "General Linear Model - Without global signal";
    ${FSLDIR}/bin/fsl_glm -i ${outdir}/filtered_func_data.nii.gz -m ${outdir}/mask.nii.gz -d ${conf_dir}/design_woGSR.mat --demean --out_res=${stats_dir}/res4d_woGSR.nii.gz;


    echo "################################################";
    echo "Apply Transformations and Temporal Filtering";
    echo "################################################";

    #Directories and constants
    outbn=ppBoldv2;
    hpf=0.01;
    lpf=0.08;

    ppBold_dir=${outdir}/ppBold;
    mkdir -p $ppBold_dir

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

















