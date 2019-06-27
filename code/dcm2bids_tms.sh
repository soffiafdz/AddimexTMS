#!/bin/bash

if [ $# -eq 0 ] || [ $# -gt 2 ] ;then
	echo "usage: "$0" dcmdir [bidsdir]";
	exit 0;
elif [ $# -eq  1 ]; then
	bidsdir=$(pwd)
else
	bidsdir=$2
fi

dcmdir=$1
now=$(date +"%d%m%y")

#Functions for reiteration
conv2bids() {
	echo "Converting ${ses}";
	echo "dcm2bids -d ${dcmdir}/${sub}/${ses} -p ${sub#*-} -s ${ses#*-} -c code/config.json";
	dcm2bids -d ${dcmdir}/${sub}/${ses} -p ${sub#*-} -s ${ses#*-} -c code/config.json;
}

slicetiming() {
	if [[ 10#${sub#*-} -lt 5 ]] && [[ $ses == "ses-t0" ]]; then
		echo "Appending SliceTiming (sub $sub is pre-change)";
		sed -i 'x; ${s/$/,\n\t"TaskName": "rest",\n\t"PhaseEncodingDirection": "j-",\n\t"SliceTiming": [\n\t\t0.000000,\n\t\t1.025641,\n\t\t0.051282,\n\t\t1.076923,\n\t\t0.102564,\n\t\t1.128205,\n\t\t0.153846,\n\t\t1.179487,\n\t\t0.205128,\n\t\t1.230769,\n\t\t0.256410,\n\t\t1.282052,\n\t\t0.307692,\n\t\t1.333334,\n\t\t0.358974,\n\t\t1.384616,\n\t\t0.410256,\n\t\t1.435898,\n\t\t0.461538,\n\t\t1.487180,\n\t\t0.512820,\n\t\t1.538462,\n\t\t0.564102,\n\t\t1.589744,\n\t\t0.615385,\n\t\t1.641026,\n\t\t0.666667,\n\t\t1.692308,\n\t\t0.717949,\n\t\t1.743590,\n\t\t0.769231,\n\t\t1.794873,\n\t\t0.820513,\n\t\t1.846155,\n\t\t0.871795,\n\t\t1.897437,\n\t\t0.923077,\n\t\t1.948719,\n\t\t0.974359\n\t]/;p;x}; 1d' ${bidsdir}/${sub}/${ses}/func/${sub}_${ses}_task-rest_bold.json;
	else
		echo "Appending SliceTiming (sub $sub is post-change)";
		sed -i 'x; ${s/$/,\n\t"TaskName": "rest",\n\t"PhaseEncodingDirection": "j-",\n\t"SliceTiming": [\n\t\t0.000000,\n\t\t1.027027,\n\t\t0.054054,\n\t\t1.081081,\n\t\t0.108108,\n\t\t1.135135,\n\t\t0.162162,\n\t\t1.189189,\n\t\t0.216216,\n\t\t1.243244,\n\t\t0.270270,\n\t\t1.297298,\n\t\t0.324324,\n\t\t1.351352,\n\t\t0.378378,\n\t\t1.405406,\n\t\t0.432432,\n\t\t1.459460,\n\t\t0.486486,\n\t\t1.513514,\n\t\t0.540541,\n\t\t1.567568,\n\t\t0.594595,\n\t\t1.621622,\n\t\t0.648649,\n\t\t1.675676,\n\t\t0.702703,\n\t\t1.729730,\n\t\t0.756757,\n\t\t1.783784,\n\t\t0.810811,\n\t\t1.837838,\n\t\t0.864865,\n\t\t1.891892,\n\t\t0.918919,\n\t\t1.945947,\n\t\t0.972973\n\t]/;p;x}; 1d' ${bidsdir}/${sub}/${ses}/func/${sub}_${ses}_task-rest_bold.json;
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
		sed -i "${l}s/$/,\n\t\"EffectiveEchoSpacing\": $ES,\n\t\"TotalReadoutTime\": $TRT/" $i
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
			sed -i "${l}s|$|,\n\t\"PhaseEncodingDirection\": \"j\",\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT}\"|" $i
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
			sed -i "${l}s|$|,\n\t\"PhaseEncodingDirection\": \"j\",\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT}\"|" $i
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
		# deface;
	else
		echo "ses-t0 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t1 ] && [ -d ${dcmdir}/${sub}/ses-t1 ] ; then
		ses="ses-t1";
		conv2bids;
		slicetiming;
		ees_trt;
		# deface;
	else
		echo "ses-t1 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t14 ] && [ -d ${dcmdir}/${sub}/ses-t14 ] ; then
		ses="ses-t14";
		conv2bids;
		slicetiming;
		ees_trt;
		# deface;
	else
		echo "ses-t1-4 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t2 ] && [ -d ${dcmdir}/${sub}/ses-t2 ] ; then
		ses="ses-t2";
		conv2bids;
		slicetiming;
		ees_trt;
		# deface;
	else
		echo "ses-t2 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t3 ] && [ -d ${dcmdir}/${sub}/ses-t3 ] ; then
		ses="ses-t3";
		conv2bids;
		slicetiming;
		ees_trt;
		# deface;
	else
		echo "ses-t3 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t4 ] && [ -d ${dcmdir}/${sub}/ses-t4 ] ; then
		ses="ses-t4";
		conv2bids;
		slicetiming;
		ees_trt;
		# deface;
	else
		echo "ses-t4 not found or already converted";
	fi

	if [ ! -d ${bidsdir}/${sub}/ses-t5 ] && [ -d ${dcmdir}/${sub}/ses-t5 ] ; then
		ses="ses-t5";
		conv2bids;
		slicetiming;
		ees_trt;
		# deface;
	else
		echo "ses-t5 not found or already converted";
	fi


done


echo "Deleting excessive files and moving tmp_bids directory"
rm  ${bidsdir}/*/*/fmap/*.bval
rm  ${bidsdir}/*/*/fmap/*.bvec

