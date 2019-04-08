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
        if [[ $ses == "ses-t0" ]]; then 
			echo "Appending SliceTiming (sub $sub is pre-change)";
			sed -i 'x; ${s/$/,\n\t"TaskName": "rest",\n\t": "j-",\n\t"SliceTiming": [\n\t\t0.000000,\n\t\t1.025128,\n\t\t0.051256,\n\t\t1.076385,\n\t\t0.102513,\n\t\t1.127641,\n\t\t0.153769,\n\t\t1.178897,\n\t\t0.205026,\n\t\t1.230154,\n\t\t0.256282,\n\t\t1.281410,\n\t\t0.307538,\n\t\t1.332666,\n\t\t0.358795,\n\t\t1.383923,\n\t\t0.410051,\n\t\t1.435179,\n\t\t0.461308,\n\t\t1.486435,\n\t\t0.512564,\n\t\t1.537692,\n\t\t0.563820,\n\t\t1.588948,\n\t\t0.615077,\n\t\t1.640204,\n\t\t0.666333,\n\t\t1.691461,\n\t\t0.717590,\n\t\t1.742717,\n\t\t0.768846,\n\t\t1.793973,\n\t\t0.820103,\n\t\t1.845230,\n\t\t0.871359,\n\t\t1.896486,\n\t\t0.922615,\n\t\t1.947742,\n\t\t0.973872\n\t]/;p;x}; 1d' ${bidsdir}/${sub}/${ses}/func/${sub}_${ses}_task-rest_bold.json;
		else
			echo "Appending SliceTiming (sub $sub is pre-change)";
			#sed -i 'x; ${s/$/,\n\t"TaskName": "rest",\n\t": "j-",\n\t"SliceTiming": [\n\t\t0.000000,\n\t\t1.025128,\n\t\t0.051256,\n\t\t1.076385,\n\t\t0.102513,\n\t\t1.127641,\n\t\t0.153769,\n\t\t1.178897,\n\t\t0.205026,\n\t\t1.230154,\n\t\t0.256282,\n\t\t1.281410,\n\t\t0.307538,\n\t\t1.332666,\n\t\t0.358795,\n\t\t1.383923,\n\t\t0.410051,\n\t\t1.435179,\n\t\t0.461308,\n\t\t1.486435,\n\t\t0.512564,\n\t\t1.537692,\n\t\t0.563820,\n\t\t1.588948,\n\t\t0.615077,\n\t\t1.640204,\n\t\t0.666333,\n\t\t1.691461,\n\t\t0.717590,\n\t\t1.742717,\n\t\t0.768846,\n\t\t1.793973,\n\t\t0.820103,\n\t\t1.845230,\n\t\t0.871359,\n\t\t1.896486,\n\t\t0.922615,\n\t\t1.947742,\n\t\t0.973872\n\t]/;p;x}; 1d' ${bidsdir}/${sub}/${ses}/func/${sub}_${ses}_task-rest_bold.json;
		fi
	else
		echo "Appending SliceTiming (sub $sub is post-change)";
		sed -i 'x; ${s/$/,\n\t"TaskName": "rest",\n\t": "j-",\n\t"SliceTiming": [\n\t\t0.000000,\n\t\t1.027027,\n\t\t0.054054,\n\t\t1.081081,\n\t\t0.108108,\n\t\t1.135135,\n\t\t0.162162,\n\t\t1.189189,\n\t\t0.216216,\n\t\t1.243244,\n\t\t0.270270,\n\t\t1.297298,\n\t\t0.324324,\n\t\t1.351352,\n\t\t0.378378,\n\t\t1.405406,\n\t\t0.432432,\n\t\t1.459460,\n\t\t0.486486,\n\t\t1.513514,\n\t\t0.540541,\n\t\t1.567568,\n\t\t0.594595,\n\t\t1.621622,\n\t\t0.648649,\n\t\t1.675676,\n\t\t0.702703,\n\t\t1.729730,\n\t\t0.756757,\n\t\t1.783784,\n\t\t0.810811,\n\t\t1.837838,\n\t\t0.864865,\n\t\t1.891892,\n\t\t0.918919,\n\t\t1.945947,\n\t\t0.972973\n\t]/;p;x}; 1d' ${bidsdir}/${sub}/${ses}/func/${sub}_${ses}_task-rest_bold.json;
	fi
}

ees_trt() {
	for i in $(ls ${bidsdir}/${sub}/${ses}/func/*.json); do
		subn=${sub#*-}
		l=$(cat $i | grep -v "^#" | wc -l)
		l=$((l-1))
		if [ $ses == "ses-t0" ] && (( 10#$subn >= 1 )) && (( 10#$subn <= 4 )); then
			ES=0.000576
			TRT=0.04033
		else
			ES=0.000698
			TRT=0.04884
		fi
		echo "$sub ${ses}: $ES $TRT"
		sed -i "${l}s/$/,\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT}/" $i
	done


	for i in $(ls ${bidsdir}/${sub}/${ses}/dwi/*.json); do
		subn=${sub#*-}
		l=$(cat $i | grep -v "^#" | wc -l)
		l=$((l-1))
		case $subn in 
			00[1-4])
				case $ses in
					"ses-t0")
						ES=0.000620
						TRT=0.04833
					;;
					*)
						ES=0.000803
						TRT=0.06265
					;;
				esac
			;;
			*)
				ES=0.000847
				TRT=0.06265
			;;
		esac
		echo "$sub ${ses}: $ES $TRT"
		sed -i "${l}s/$/,\n\t\"PhaseEncodingDirection\": \"j-\",\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT}/" $i
	done



	for i in $(ls ${bidsdir}/${sub}/${ses}/fmap/*.json); do
		subn=${sub#*-}
		l=$(cat $i | grep -v "^#" | wc -l)
		l=$((l-1))
		if grep -q FM_DTI $i; then
			echo "$(basename $i) is a fieldmap for DTI";
			if [ $ses == "ses-t0" ] && [ $sub == "sub-001" ]; then
				ES=0.000619
				TRT=0.04832
			else
				case $subn in 
					00[1-4])
						case $ses in
							"ses-t0")
								ES=0.000620
								TRT=0.004833
							;;
							*)
								ES=0.000803
								TRT=0.06265
							;;
						esac
					;;
					*)
						ES=0.000847
						TRT=0.06265
					;;
				esac
			fi
			echo "$subn ${ses}: $ES $TRT"
			sed -i "${l}s|$|,\n\t\"PhaseEncodingDirection\": \"j\",\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT},\n\t\"IntendedFor\": \"dwi/${sub}_${ses}_dwi.nii.gz\"|" $i
		else 
			echo "$(basename $i) is not a fieldmap for DTI, so it's for EPI";
			case $ses in
				"ses-t0")
					case $subn in 
						001)
							ES=0.000635
							TRT=0.04444
						;;
						00[2-4])
							ES=0.000571
							TRT=0.03994
						;;
						*)
							ES=0.000698
							TRT=0.04884
					esac
				;;
				*)
					ES=0.000698
					TRT=0.04884
				;;
			esac
			echo "$subn ${ses}: $ES $TRT"
			sed -i "${l}s|$|,\n\t\"PhaseEncodingDirection\": \"j\",\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT},\n\t\"IntendedFor\": \"func/${sub}_${ses}_task-rest_bold.nii.gz\"|" $i
		fi
	done
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
		ees_trt;
		deface;
	else
		echo "ses-t0 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t1 ] && [ -d ${dcmdir}/${sub}/ses-t1 ] ; then
		ses="ses-t1";
		conv2bids;
		slicetiming;
		ees_trt;
		deface;
	else
		echo "ses-t1 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t14 ] && [ -d ${dcmdir}/${sub}/ses-t14 ] ; then
		ses="ses-t14";
		conv2bids;
		slicetiming;
		ees_trt;
		deface;
	else
		echo "ses-t1-4 not found or already converted";
	fi 

	if [ ! -d ${bidsdir}/${sub}/ses-t2 ] && [ -d ${dcmdir}/${sub}/ses-t2 ] ; then
		ses="ses-t2";
		conv2bids;
		slicetiming;
		ees_trt;
		deface;
	else
		echo "ses-t2 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t3 ] && [ -d ${dcmdir}/${sub}/ses-t3 ] ; then
		ses="ses-t3";
		conv2bids;
		slicetiming;
		ees_trt;
		deface;
	else
		echo "ses-t3 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t4 ] && [ -d ${dcmdir}/${sub}/ses-t4 ] ; then
		ses="ses-t4";
		conv2bids;
		slicetiming;
		ees_trt;
		deface;
	else
		echo "ses-t4 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t5 ] && [ -d ${dcmdir}/${sub}/ses-t5 ] ; then
		ses="ses-t5";
		conv2bids;
		slicetiming;
		ees_trt;
		deface;
	else
		echo "ses-t5 not found or already converted";
	fi


done

fi

echo "Deleting excessive files and moving tmp_bids directory"
rm  ${bidsdir}/*/*/fmap/*.bval
rm  ${bidsdir}/*/*/fmap/*.bvec

