#!/bin/bash
#Add the IntendedFor section to fieldmapping files in bids
## "IntendedFor": "func/sub-01_task-motor_bold.nii.gz"
echo "BOLD jsons"
for i in $(ls */*/func/*.json); do
	base=${i%/*/*}
	sub=${base%/*}
	subn=${sub#*-}
	ses=${base#*/}
	l=$(cat $i | grep -v "^#" | wc -l)
	l=$((l-1))
	if [ $ses == "ses-t0" ] && (( 10#$subn >= 1 )) && (( 10#$subn <= 4 )); then
		ES=0.000576
		TRT=0.04033
	else
		ES=0.000698
		TRT=0.04884
	fi
	echo "subn is $subn ses is $ses $ES $TRT"
	sed -i "${l}s/$/,\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT}/" $i
done

echo "DWI jsons"
for i in $(ls */*/dwi/*.json); do
	base=${i%/*/*}
	sub=${base%/*}
	subn=${sub#*-}
	ses=${base#*/}
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
	echo "sub is $subn ses is $ses $ES $TRT"
	sed -i "${l}s/$/,\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT}/" $i
done

echo "FMap jsons"
for i in $(ls */*/fmap/*.json); do
	base=${i%/*/*}
	sub=${base%/*}
	subn=${sub#*-}
	ses=${base#*/}
	l=$(cat $i | grep -v "^#" | wc -l)
	l=$((l-1))
	if grep -q FM_DTI $i; then
		echo "$i is a fieldmap for DTI";
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
		echo "sub is $subn ses is $ses $ES $TRT"
		sed -i "${l}s|$|,\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT},\n\t\"IntendedFor\": \"${ses}/dwi/${base/\//_}_dwi.nii.gz\"|" $i
	else 
		echo "$i is not a fieldmap for DTI, so it's for EPI";
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
		echo "sub is $subn ses is $ses $ES $TRT"
		sed -i "${l}s|$|,\n\t\"EffectiveEchoSpacing\": ${ES},\n\t\"TotalReadoutTime\": ${TRT},\n\t\"IntendedFor\": \"${ses}/func/${base/\//_}_task-rest_bold.nii.gz\"|" $i
	fi
done
