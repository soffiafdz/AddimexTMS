#!/bin/bash

if [ $# -eq 0 ];then

    echo "usage: "$0" dcmdir [bidsdir]";
    exit 0;

else

dcmdir=$1
bidsdir=$(pwd)
now=$(date +"%d%m%y")

#Functions for reiteration 
conv2bids() {
    echo "Converting ${ses}"; 
    echo "dcm2bids -d ${dcmdir}/${sub}/${ses} -p ${sub#*-} -s ${ses#*-} -c code/config.json";
    dcm2bids -d ${dcmdir}/${sub}/${ses} -p ${sub#*-} -s ${ses#*-} -c code/config.json;
}

slicetiming() {
    if [[ ${sub#*-} -lt 5 ]]; then
        echo "Appending SliceTiming (sub $sub is pre-change)";
        sed -i 'x; ${s/$/,\n    "SliceTiming": [\n        0.000000,\n        1.025128,\n        0.051256,\n        1.076385,\n        0.102513,\n        1.127641,\n        0.153769,\n        1.178897,\n        0.205026,\n        1.230154,\n        0.256282,\n        1.281410,\n        0.307538,\n        1.332666,\n        0.358795,\n        1.383923,\n        0.410051,\n        1.435179,\n        0.461308,\n        1.486435,\n        0.512564,\n        1.537692,\n        0.563820,\n        1.588948,\n        0.615077,\n        1.640204,\n        0.666333,\n        1.691461,\n        0.717590,\n        1.742717,\n        0.768846,\n        1.793973,\n        0.820103,\n        1.845230,\n        0.871359,\n        1.896486,\n        0.922615,\n        1.947742,\n        0.973872\n    ]/;p;x}; 1d' ${bidsdir}/${sub}/${ses}/func/${sub}_${ses}_task-rest_bold.json;
    else
        echo "Appending SliceTiming (sub $sub is post-change)";
        sed -i 'x; ${s/$/,\n    "SliceTiming": [\n        0.000000,\n        1.027027,\n        0.054054,\n        1.081081,\n        0.108108,\n        1.135135,\n        0.162162,\n        1.189189,\n        0.216216,\n        1.243244,\n        0.270270,\n        1.297298,\n        0.324324,\n        1.351352,\n        0.378378,\n        1.405406,\n        0.432432,\n        1.459460,\n        0.486486,\n        1.513514,\n        0.540541,\n        1.567568,\n        0.594595,\n        1.621622,\n        0.648649,\n        1.675676,\n        0.702703,\n        1.729730,\n        0.756757,\n        1.783784,\n        0.810811,\n        1.837838,\n        0.864865,\n        1.891892,\n        0.918919,\n        1.945947,\n        0.972973\n    ]/;p;x}; 1d' ${bidsdir}/${sub}/${ses}/func/${sub}_${ses}_task-rest_bold.json;
    fi
}

deface() {
    t1=${bidsdir}/${sub}/${ses}/anat/${sub}_${ses}_T1w.nii.gz
    pydeface --force $t1 --outfile $t1
}


for i in $(ls -d ${dcmdir}/sub-0*); do
    sub=$(basename $i)
    echo "Subject ${sub}"

    if [ ! -d ${bidsdir}/${sub}/ses-t0 ] && [ -d ${dcmdir}/${sub}/ses-t0 ]; then
        ses="ses-t0";
        conv2bids;
        slicetiming;
        deface;
    else
        echo "ses-t0 not found or already converted";
    fi

    if [ ! -d ${bidsdir}/${sub}/ses-t1 ] && [ -d ${dcmdir}/${sub}/ses-t1 ] ; then
        ses="ses-t1";
        conv2bids;
        slicetiming;
        deface;
    else
        echo "ses-t1 not found or already converted";
    fi

    if [ ! -d ${bidsdir}/${sub}/ses-t14 ] && [ -d ${dcmdir}/${sub}/ses-t14 ] ; then
        ses="ses-t14";
        conv2bids;
        slicetiming;
        deface;
    else
        echo "ses-t1-4 not found or already converted";
    fi 

    if [ ! -d ${bidsdir}/${sub}/ses-t2 ] && [ -d ${dcmdir}/${sub}/ses-t2 ] ; then
        ses="ses-t2";
        conv2bids;
        slicetiming;
        deface;
    else
        echo "ses-t2 not found or already converted";
    fi

    if [ ! -d ${bidsdir}/${sub}/ses-t3 ] && [ -d ${dcmdir}/${sub}/ses-t3 ] ; then
        ses="ses-t3";
        conv2bids;
        slicetiming;
        deface;
    else
        echo "ses-t3 not found or already converted";
    fi

    if [ ! -d ${bidsdir}/${sub}/ses-t4 ] && [ -d ${dcmdir}/${sub}/ses-t4 ] ; then
        ses="ses-t4";
        conv2bids;
        slicetiming;
        deface;
    else
        echo "ses-t4 not found or already converted";
    fi

    if [ ! -d ${bidsdir}/${sub}/ses-t5 ] && [ -d ${dcmdir}/${sub}/ses-t5 ] ; then
        ses="ses-t5";
        conv2bids;
        slicetiming;
        deface;
    else
        echo "ses-t5 not found or already converted";
    fi

    sleep 2

done

fi

echo "Deleting excessive files and moving tmp_bids directory"
rm  ${bidsdir}/*/*/fmap/*.bval
rm  ${bidsdir}/*/*/fmap/*.bvec

