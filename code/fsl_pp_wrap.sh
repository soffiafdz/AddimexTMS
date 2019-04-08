#!/bin/bash

###Wrapper for the bash script to run preprocessing with fsl... Will execute all of the files not existing in the preproc_fsl directory
##Example of path in bids format
##/run/media/sofdez/Alpha/TMS/bids/sub-0*/ses-t*/[func,anat]/*.nii.gz

#Check if the fsl_pp.sh and R scripts exist
if [ ! -e ./code/fsl_pp.sh ]; then
    echo "Can't find preprocessing script.";
    exit 0;
elif [ ! -e ./code/dp2.R ]; then
    echo "Can't find dp2.R script.";
    exit 0;
elif [ ! -e ./code/colpeaks.R ]; then
    echo "Can't find colpeaks.R script.";
    exit 0;
elif [ ! -e ./derivatives/preproc_fsl ]; then
    echo "There is no preproc_fsl directory. All subs will be preprocessed (again?). Create the directory and run again.";
    exit 0;
fi

for sub in $(ls -d sub-*); do
    subn=${sub#*-};
    echo "Looking for sessions inside ${sub}...";
    for ses in $(ls $sub); do 
        sesn=${ses#*-};
        if [ ! -e ./derivatives/preproc_fsl/${sub}/${ses}/ppBold/ppBoldv2_MNI3mm*.nii.gz ] ; then
            echo "$subn ${sesn} is not preprocessed yet, running fsl_pp script...";
            code/fsl_pp.sh $subn $sesn;
        else
            echo "${sesn} is already preprocessed and in the preproc_fsl directory. Moving on..."
        fi
    done
done

echo "All subs and sessions have been preprocessed." 

