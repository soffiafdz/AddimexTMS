#!/bin/bash

##Example of path in bids format
##/run/media/sofdez/Alpha/TMS/bids/sub-0*/ses-t*/[func,anat]/*.nii.gz

#For loop here
#Insert as arguments no of subs and/or no of sessions

###This is the thing that changes in the loop for each sub/sess

usg="Usage: $0 <sub (001 002 ...)> <sess (t0 ... t14)> Note: run this script from one parent directory of the bids directory"
sub=sub-${1};
ses=ses-${2};
root1=$(pwd)/${sub}
root2=${root1}/${ses}

if [ ! -e $root1 ]; then
    echo "can't find that subject in the bids directory";
    exit 0;
elif [ ! -e $root2 ]; then
    echo "can't find that session in the ${sub} directory";
    exit 0;
else
    echo "Running preprocessing script of ${sub}, ${ses}"
    #Constants and variables
    bold=${root2}/func/${sub}_${ses}_task-rest_bold.nii.gz;
    pre_str=${root2}/anat/${sub}_${ses}_T1w.nii.gz;
    basedir=$(dirname ${0});
    bold_bn=$(basename $bold .nii.gz); 
    outdir=derivatives/preproc_fsl/${sub}/${ses};

    echo "bold is $bold"
    echo "pre_str is $pre_str"
    echo "basedir is $basedir"
    echo "bold_bn is $bold_bn"
    echo "outdir is $outdir"
fi
