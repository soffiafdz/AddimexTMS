#!/bin/bash

##Constants
usg="Usage: $0 <sub (001 025 ...)> <sess (t0 t14)> {Net name: if not specified all nets will be extracted} Note: putting all in the sub will run all the existing subs in the input directory"
bdir=$(pwd)
now=$(date +"%d%m%y")
nets=(aud cereb co_tc d_att dmn fp_tc mem_r sal sm_h sm_m sub_c uncert v_att vis wb)
input=preproc_fsl
mats_dir=${bdir}/graphs/matrices/power_${now}
raw=${mats_dir}/raw
posneg=${mats_dir}/posneg
errors=0

##Functions 
brain_mask() { #input #sub_ses
	if [ -e ${1}/ppBold/brainmask_MNI3mm_${2}.nii.gz ]; then
		echo "Brain mask already exists for $2"
		echo "##########################################################"
		cd ${1}/ppBold
	else
		echo "Creating brain mask of preprocessed data for $2"
		cd ${1}/ppBold
		fslmaths ppBoldv2_MNI3mm_${2}_task-rest_bold.nii.gz -Tmean -sqr -bin brainmask_MNI3mm_${2}.nii.gz
		echo "Brain mask is done and saved as brainmask_MNI3mm_${2}.nii.gz"
		echo "##########################################################"
	fi
}
tx_sham() { #subn
	sham=('001' '002' '005' '006' '008' '009' '010' '012' '013' '018' '019' '022' '027')
	tx=('003' '004' '007' '011' '014' '015' '016' '017' '020' '021' '023' '024' '025' '026' '028')
	#Seeing if the sub is sham
	for j in ${sham[@]}; do
		if [[ $j -eq $1 ]] ; then
			gr=sham
		fi
	done
    
	#Seeing if the sub is tx
	for j in ${tx[@]}; do
		if [[ $j -eq $1 ]] ; then
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
			echo "ERROR: Sub $1 group is set wrong"
			exit 0
			;; 
	esac
}
adj_mat() { #sub_ses gr net out
	atlases=${bdir}/atlases/power_240818/rois/nets
	echo "Starting with ${3} network:"
	echo "Creating a matrix with Power's ${3} atlas";
	3dNetCorr -prefix ${1}_matrix_${3} \
		-inset ppBoldv2_woGSR_MNI3mm_${1}_task-rest_bold.nii.gz \
		-mask brainmask_MNI3mm_${1}.nii.gz \
		-in_rois ${atlases}/${3}/${3}_network.nii.gz \
		-fish_z
            
	echo "Matrix of ${3} is done..."
	echo "##########################################################"
	echo "Moving data to $4"
	mkdir -p $4
	mv ${1}_matrix_${3}* ${4}
	echo "##########################################################"
}
extract_r_z_mats() { #.netcc: $posneg
	echo "Extracting r-values and Z-values matrices"
	mkdir -p $2
	bname=$(basename $1)
	csv=${bname}.csv
	cp $1 $2
	cd $2
	mv ${bname}.netcc $csv
	lines="$(cat $csv | grep -v "^#" | sed "2 d" | wc -l)"
	lines1=$((lines/2+1))
	lines2=$(((lines-1)/2))
	cat $csv | grep -v "^#" | sed "2 d" | head -n $lines1 > ${bname%*000}r.csv
	sed -i '1d' ${bname%*000}r.csv
	cat $csv | grep -v "^#" | sed "2 d" | head -n 1 > ${bname%*000}z.csv
	cat $csv | grep -v "^#" | tail -n $lines2 >> ${bname%*000}z.csv
	sed -i '1d' ${bname%*000}z.csv
	cd $bdir
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
	aud=13; cereb=4; co_tc=14; d_att=11; dmn=58; fp_tc=25; mem_r=5; sal=18; sm_h=30; sm_m=5; sub_c=13; uncert=28; v_att=9; vis=31; wb=264
	n=$(awk '{n+=1} END {print n}' $1)
	lenght=${2}
	if [[ -z $errors ]]; then errors=0 ; fi
	mat1=$(basename $1}
	echo "Reviewing $mat1 dimensions"
	if [[ $n != ${!lenght} ]]; then
		echo " Matrix $mat1 has the wrong dimensions: $n ; instead of ${!length}" >> ${mats_dir}/shitty_nets.txt
		errors=$((errors+1))
	fi
	echo "##########################################################"
}
rm_dropouts() { #dir 005 009 028
	for i in ${@:2}; do 
		if [[ -e ${1}/sub-${i}* ]]; then
			echo "Removing sub $i"
			rm ${1}/sub-${i}*
		fi
	done
	echo "##########################################################"
}
##Conditions
if [[ $# -lt 2 ]] && [[ $1 != "ALL" ]]; then
	echo $usg;
	exit 0;
elif [[ $# -gt 2 ]]; then
	for i in ${nets[@]}; do
		if [[ $3 == $i ]] && [[ -d ${bdir}/atlases/power_240818/rois/nets/${3} ]]; then
			net=${3}
		fi
	done
	if [[ -z $net ]]; then
	echo "ERROR: Net $net wasn't found"
	exit 0;
	else
		if [[ $1 == "ALL" ]]; then
			if [[ ! -d $input ]]; then
				echo "ERROR: Directory $input not found"
				exit 0;
			fi
			for i in $(ls -d ${input}/*t[0-2]*.rsfMRIv2); do
				dir=${i#*/}
				sub_ses=${dir%_task*}
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
				adj_mat $sub_ses $gr $net $raw
				#Extracting significant info of matrices
				extract_r_z_mats ${raw}/${sub_ses}_matrix_${net}_000.netcc ${posneg}/${net}
				#Matrix of positive values
				pos_mat ${posneg}/${net}/${sub_ses}_matrix_${net}
				#Review mats dimensions
				for mat in $r $z; do
					review_mats $mat $net
				done
			done
		echo "Finished with all subs"
		else
			sub_ses=sub-${1}_ses-${2}
			input1=preproc_fsl/${sub_ses}_task-rest_bold.rsfMRIv2
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
			adj_mat $sub_ses $gr $net $raw
			#Extracting significant info of matrices
			extract_r_z_mats ${raw}/${sub_ses}_matrix_${net}_000.netcc ${posneg}/${net}
			#Matrix of positive values
			pos_mat ${posneg}/${net}/${sub_ses}_matrix_${net}
			#Review mats dimensions
			for mat in $r $z; do
				review_mats $mat $net
			done
		fi
	fi
else
	for net in ${nets[@]}; do
		if [[ -d ${bdir}/atlases/power_240818/rois/nets/${net} ]]; then
			echo "ERROR: $net not found"
			exit 0;
		fi
		if [[ $1 == "ALL" ]]; then
			input=preproc_fsl
			if [[ ! -d $input ]]; then
				echo "ERROR: Directory $input not found"
				exit 0;
			fi
			for i in $(ls -d ${input}/*t[0-2]*.rsfMRIv2); do
				dir=${i#*/}
				sub_ses=${dir%_task*}
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
				adj_mat $sub_ses $gr $net $raw
				#Extracting significant info of matrices
				extract_r_z_mats ${raw}/${sub_ses}_matrix_${net}_000.netcc ${posneg}/${net}
				#Matrix of positive values
				pos_mat ${posneg}/${net}/${sub_ses}_matrix_${net}
				#Review mats dimensions
				for mat in $r $z; do
					review_mats $mat $net
				done
			done
		echo "Finished with all subs"
		else
			sub_ses=sub-${1}_ses-${2}
			input1=preproc_fsl/${sub_ses}_task-rest_bold.rsfMRIv2
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
			adj_mat $sub_ses $gr $net $raw
			#Extracting significant info of matrices
			extract_r_z_mats ${raw}/${sub_ses}_matrix_${net}_000.netcc ${posneg}/${net}
			#Matrix of positive values
			pos_mat ${posneg}/${net}/${sub_ses}_matrix_${net}
		fi
	done
fi
#Remove dropout subs
rm_dropouts ${mats_dir}/pos*/* 005 009 028
#Total of errors
if [[ $errors -gt 0 ]]; then
	echo "There was a total of $errors matrices with the wrong dimensions. Check ${mats_dir}/shitty_nets.txt for more info"
fi
echo "#########################DONE##############################"
