#!/bin/bash

##Constants
usg="Usage: $0 <sub (001 025 ... ALL)> <sess (t0 t14 ... ALL)> [Net name: if not specified all nets will be extracted] Note: putting ALL in the sub will run all the existing subs in the input directory"

now=$(date +"%d%m%y")
time=$(date +"%H:%M")
nets=(aud cereb co_tc d_att dmn fp_tc mem_r sal sm_h sm_m subc uncert v_att vis wb)
home=$(pwd)
input=${home}/derivatives/preproc_fsl
atlases=${home}/derivatives/graphs/atlases/power_240818/rois/nets
mats_dir=${home}/derivatives/graphs/matrices/power_${now}
raw=${mats_dir}/raw
posneg=${mats_dir}/posneg
errors=0

mkdir -p $mats_dir
##Functions 
brain_mask() { #input #sub_ses
    if [ -e ${1}/ppBold/brainmask_MNI3mm_${2}.nii.gz ]; then
        echo "Brain mask already exists for $2"
        echo "##########################################################"
        cd ${1}/ppBold
    else
        echo "Creating brain mask of preprocessed data for $2"
        cd ${1}/ppBold
        fslmaths ppBoldv2_woGSR_MNI3mm_${2}.nii.gz -Tmean -sqr -bin brainmask_MNI3mm_${2}.nii.gz
        echo "Brain mask is done and saved as brainmask_MNI3mm_${2}.nii.gz"
        echo "##########################################################"
    fi
}
tx_sham() { #subn
    num_sub=${1#0}
    num_sub=${num_sub#0}
    sham=('1' '2' '5' '6' '8' '9' '10' '12' '13' '18' '19' '22' '27' '29' '30' '33')
    tx=('3' '4' '7' '11' '14' '15' '16' '17' '20' '21' '23' '24' '25' '26' '28' '31' '32' '34')
    #Seeing if the sub is sham
    for j in ${sham[@]}; do
        if [[ $j == $num_sub ]] ; then
            gr=sham
        fi
    done
    
    #Seeing if the sub is tx
    for j in ${tx[@]}; do
        if [[ $j == $num_sub ]] ; then
            gr=tx
        fi
    done

    case $gr in 
        sham) 
            echo "Sub $1 is sham" 
            echo "##########################################################"
            ;; 
        tx) 
            echo "Sub $1 is tx" 
            echo "##########################################################"
            ;; 
        *) 
            echo "Sub $1 group's unknown"
            echo "##########################################################"
            gr=na
            ;; 
    esac
}
adj_mat() { #sub_ses gr net out atlas
    atlases=$5
    echo "Creating a matrix with Power's ${3} atlas";
    3dNetCorr -prefix ${1}_matrix_${3} \
        -inset ppBoldv2_woGSR_MNI3mm_${1}.nii.gz \
        -mask brainmask_MNI3mm_${1}.nii.gz \
        -in_rois ${atlases}/${3}/${3}_network.nii.gz \
        -fish_z
    echo "Matrix of ${3} is done..."
    echo "##########################################################"
    echo "Moving data to ${4}/${3}/${2}"
    mkdir -p ${4}/${3}/${2}
    mv ${1}_matrix_${3}* ${4}/${3}/${2}
    echo "##########################################################"
}
extract_r_z_mats() { #.netcc: $posneg
    echo "Extracting r-values and Z-values matrices"
    mkdir -p $2
    bname=$(basename $1 .netcc)
    csv=${bname}.csv
    cp $1 $2
    cd $2
    mv ${bname}.netcc $csv
    lines="$(cat $csv | grep -v "^#" | sed "2 d" | wc -l)"
    lines1=$((lines/2+1))
    lines2=$(((lines-1)/2))
    cat $csv | grep -v "^#" | sed "2 d" | head -n $lines1 > ${bname%*000}r.csv
    #sed -i '1d' ${bname%*000}r.csv
    cat $csv | grep -v "^#" | sed "2 d" | head -n 1 > ${bname%*000}z.csv
    cat $csv | grep -v "^#" | tail -n $lines2 >> ${bname%*000}z.csv
    #sed -i '1d' ${bname%*000}z.csv
    cd $home
    echo "##########################################################"
}
pos_mats() { 
    echo "Converting matrices to just positive values"
    dir=$(dirname $1)
    mkdir -p ${dir/posneg/pos}
    r=${1}_r.csv
    z=${1}_z.csv
    awk -vOFS='\t' '{for(i=1;i<=NF;i++)if($i<0)$i=0}1' $r > ${r/posneg/pos}
    awk -vOFS='\t' '{for(i=1;i<=NF;i++)if($i<0)$i=0}1' $z > ${z/posneg/pos}
    echo "##########################################################"
}
review_mats() { #mat #net
    #Networks lenghts
    aud=14; cereb=5; co_tc=15; d_att=12; dmn=59; fp_tc=26; mem_r=6; sal=19; sm_h=31; sm_m=6; subc=14; uncert=29; v_att=10; vis=32; wb=265
    if [[ -z $errors ]]; then errors=0 ; fi
    n=$(awk '{n+=1} END {print n}' $1)
    mat1=$(basename $1)
    netn=${mat1#*_matrix_}
    netn=${netn%_*}
    ln=${!netn}
    echo "Reviewing $mat1 dimensions"
    if [[ $n != $ln ]]; then
        echo "Matrix $mat1 has the wrong dimensions: $n ; instead of $ln "
        echo " Matrix $mat1 has the wrong dimensions: $n ; instead of $ln " >> ${mats_dir}/log_nets.txt
        errors=$((errors+1))
    fi
    echo "##########################################################"
}


mats_script_all() {
    for i in $(ls -d derivatives/preproc_fsl/*/ses-t[0-2]*); do
        sub_ses=${i#*/*/*}
        sub_ses=${sub_ses/\//_}
        sub=${sub_ses%_ses*}
        subn=${sub#*-}
        ses=${sub_ses#sub*_}
        sesn=${ses#*-}
        ##########################################################
        echo "Starting with sub $sub_ses : net $net";
        echo "##########################################################"
        #Locating/creating brain mask
        brain_mask $i $sub_ses
        #Is sub sham or tx? 
        tx_sham $subn
        #Creating the adj matrices
        adj_mat $sub_ses $gr $net $raw $atlases
        #Extracting significant info of matrices
        extract_r_z_mats ${raw}/${net}/${gr}/${sub_ses}_matrix_${net}_000.netcc ${posneg}/${net}/${gr}
        #Matrix of positive values
        pos_mats ${posneg}/${net}/${gr}/${sub_ses}_matrix_${net}
        #Review mats dimensions
        for mat in $r $z; do
            review_mats $mat $net
        done
    done
    echo "Finished with all subs"
}

mats_script_sub() { #sub #ses 
    sub_ses=sub-${1}_ses-${2}
    input1=derivatives/preproc_fsl/sub-${1}/ses-${2}
    if [[ ! -d $input1 ]]; then
        echo "ERROR: Directory $input1 not found"
        exit 0;
    fi
    echo "Starting with sub $1 $2: net $net";
    echo "##########################################################"
    #Locating/creating brain mask
    brain_mask $input1 $sub_ses
    #Is sub sham or tx? 
    tx_sham $1 
    #Creating the adj matrices
    adj_mat $sub_ses $gr $net $raw $atlases
    #Extracting significant info of matrices
    extract_r_z_mats ${raw}/${net}/${gr}/${sub_ses}_matrix_${net}_000.netcc ${posneg}/${net}/${gr}
    #Matrix of positive values
    pos_mats ${posneg}/${net}/${gr}/${sub_ses}_matrix_${net}
    #Review mats dimensions
    for mat in $r $z; do
        review_mats $mat $net
    done
    echo "Finished with sub $1 $2: net $net";
    echo "##########################################################"
}


##Conditions
echo "Process $now $time ..." >> ${mats_dir}/log_nets.txt
if [[ $# -lt 2 ]] && [[ $1 != "ALL" ]]; then
    echo $usg;
    exit 0;
elif [[ $# -gt 2 ]]; then
    for i in ${nets[@]}; do
        if [[ $3 == $i ]] && [[ -d ${atlases}/${3} ]]; then
            net=${3}
        fi
    done
    if [[ -z $net ]]; then
    echo "ERROR: Net $net wasn't found"
    exit 0;
    else
        if [[ $1 == "ALL" ]]; then
            mats_script_all
        else
            if [[ $2 == "ALL" ]]; then 
                for i in $(ls ${input}/sub-${1}); do
                    mats_script_sub $1 ${i#*-}
                done
            else
                mats_script_sub $1 $2
            fi
        fi
    fi
else
    for net in ${nets[@]}; do
        if [[ ! -d ${atlases}/${net} ]]; then
            echo "ERROR: $net not found"
            exit 0;
        fi
        if [[ $1 == "ALL" ]]; then
            if [[ ! -d $input ]]; then
                echo "ERROR: Directory $input not found"
                exit 0;
            fi
            mats_script_all
        else
            if [[ $2 == "ALL" ]]; then 
                for i in $(ls ${input}/sub-${1}); do
                    mats_script_sub $1 ${i#*-}
                done
            else
                mats_script_sub $1 $2
            fi
        fi
    done
fi

#Total of errors
if [[ $errors -gt 0 ]]; then
    echo "There was a total of $errors matrices with the wrong dimensions. Check ${mats_dir}/log_nets.txt for more info"
fi
echo "#########################DONE##############################"
