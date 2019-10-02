for i in $(ls graphs/adjm_0918/power/pos/*/*/*/*_[r,z].csv); do
    echo "${i#*sub-}" $(awk '{n+=1} END {print n}' ${i});
done


awk '{n+=1} END {print n}'



for (( i=1; i<${arraylength}+1; i++ ))

for i in $(ls graphs/adjm_0918/power/pos/*/*/*/*_[r,z].csv); do
    echo ${i#*sub-} $(awk '{n+=1} END {print n}' ${i});
done


awk '{n+=1} END {print n}'

##Functions
brain_mask() { #dir #sub_ses
    if [ -e ${1}/ppBold/brainmask_MNI3mm_${2}.nii.gz ]; then
        echo "Brain mask already exists for $2"
        cd ${1}/ppBold
    else
        echo "Creating brain mask of preprocessed data for $2"
        cd ${1}/ppBold
        fslmaths ppBoldv2_MNI3mm_${2}_task-rest_bold.nii.gz -Tmean -sqr -bin brainmask_MNI3mm_${2}.nii.gz
        echo "Brain mask is done and saved as brainmask_MNI3mm_${2}.nii.gz"
    fi
}

tx_sham() { #subn
    sham=('001' '002' '005' '006' '008' '009' '010' '012' '013' '018' '019' '022' '027')
    tx=('003' '004' '007' '011' '014' '015' '016' '017' '020' '021' '023' '024' '025' '026' '028')
    #Seeing if the sub is sham
    for j in ${sham[@]}; do
        if [ $j -eq $1 ] ; then
            gr=sham
        fi
    done

    #Seeing if the sub is tx
    for j in ${tx[@]}; do
        if [ $j -eq $1 ] ; then
            gr=tx
        fi
    done
}

adj_mat() { #sub_ses gr net $(pwd)/graphs/matrices/power_${now}
    echo "Starting with ${3} network:"
    echo "Creating a matrix with Power's ${3} atlas";
    3dNetCorr -prefix ${1}_matrix_${3} \
    -inset ppBoldv2_woGSR_MNI3mm_${1}_task-rest_bold.nii.gz \
    -mask brainmask_MNI3mm_${1}.nii.gz \
    -in_rois ../../../atlases/power_240818/rois/nets/${3}/${3}_network.nii.gz \
    -fish_z


    #Need to change name of network in -in rois
    if [ ${1#*s-} == "t0" ]; then
        echo "moving data to ${4}/${3}/baseline/${2}"
        mkdir -p ${4}/${3}/baseline/${2}
        mv ${1}_matrix_${3}* ${4}/${3}/baseline/${2}
    elif [ ${1#*s-} == "t14" ]; then
        echo "moving data to ${4}/${3}/2weeks_tx/${2}"
        mkdir -p ${4}/${3}/2weeks_tx/${2}
        mv ${1}_matrix_${3}* ${4}/${3}/2weeks_tx/${2}
    elif [ ${1#*s-} == "t2" ]; then
        echo "moving data to ${4}/${3}/3months/${2}"
        mkdir -p ${4}/${3}/3months/${2}
        mv ${1}_matrix_${3}* ${4}/${3}/3months/${2}
    else
        if [ $gr == "sham" ]; then
            echo "moving data to ${4}/${3}/2weeks_blind/${2}"
            mkdir -p ${4}/${3}/2weeks_blind/${2}
            mv ${1}_matrix_${3}* ${4}/${3}/2weeks_blind/${2}
        else
            echo "moving data to ${4}/${3}/2weeks_tx/${2} and ${4}/${3}/2weeks_blind/${2}"
            mkdir -p ${4}/${3}/2weeks_tx/${2}/
            mkdir -p ${4}/${3}/2weeks_blind/${2}/
            cp ${1}_matrix_${3}* ${4}/${3}/2weeks_tx/${2}
            mv ${1}_matrix_${3}* ${4}/${3}/2weeks_blind/${2}
        fi
    fi
}

extract_r_z_mats() { # in:$(pwd)/graphs/matrices/power_${now}/${net}/${ses}/${gr} out: $(pwd)graphs/adjm_${now}/power/pos_neg/${net}/${ses}/${gr}
    basedir=$(pwd)
    mkdir -p ${2}/
    cp ${1}/*.netcc $2
    cd $2
    for mat in $(ls); do
        mv $mat ${mat%*.netcc}.csv
    done
    for mat in $(ls *.csv); do
        lines="$(cat $mat | grep -v "^#" | sed "2 d" | wc -l)"
        lines1=$((lines/2+1))
        lines2=$(((lines-1)/2))
        cat $mat | grep -v "^#" | sed "2 d" | head -n $lines1 > ${mat%*000.csv}r.csv
        cat $mat | grep -v "^#" | sed "2 d" | head -n 1 > ${mat%*000.csv}z.csv
        cat $mat | grep -v "^#" | tail -n $lines2 >> ${mat%*000.csv}z.csv
    done
    cd $basedir
}

pos_mats() { #in out
    mkdir -p ${2%*sub-*}
    awk -vOFS='\t' '{for(i=1;i<=NF;i++)if($i<0)$i=0}1' $1 > ${2}/
}

unname_nodes() { #$(ls graphs/adjm_0918/power/*/${net}/*/*/*{r,z}.csv)
    sed -i '1d' $1
}

rm_dropouts() { #dir 005 009 028
    for i in ${@:2}; do
        rm ${1}/${i}
    done
}
