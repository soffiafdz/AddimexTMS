#!/bin/bash

#Variables & Constants 
usg="usage: "$0" <analysis> <session/subs> [sub(s)] [session]"
analysis_usg="analysis: 1-sub level, 2-sub and group level, 3-only group level"
sess_sub_usg="specify if analysis will run for sub(s) or session sub: 0-none (group analysis), 1-sub(s) (e.g. 001, 024 ...) 2-session (one sub, one session; e.g. t0)"



data_dir=$(pwd)
outdir=${data_dir}/derivatives/mriqc
mkdir -p $outdir

if [ $# -eq 0 ]; then
	echo $usg;
	echo $analysis_usg;
	exit 0;Home | 

elif [ $# -lt 2 ]; then
	echo "ERROR: number of variables not valid";
	echo $usg;
	exit 0;

elif [ $1 -eq 0 ] || [ $1 -gt 3 ]; then
	echo "ERROR: sub/group value not valid:";
	echo $analysis_usg;
	exit 0;

elif [ $2 -gt 2 ]; then
	echo "ERROR: subs/sessions value not valid:";
	echo $sess_sub_usg;
	exit 0;

elif [ ! -e $data_dir ]; then
	echo "ERROR: "$1" directory not found";
	exit 0;

elif [ $1 -eq 3 ]; then
	sudo docker run -i --rm -v $data_dir:/data:ro -v $outdir:/outputs poldracklab/mriqc:latest /data /out group --fd_thres 0.5 --read-only --tmpfs ${outdir}/run --tmpfs ${outdir}/tmp
	
else 
	if [ $# -eq 2 ]; then
		sudo docker run -i --rm -v $data_dir:/data:ro -v $outdir:/out poldracklab/mriqc:latest /data /out participant --fd_thres 0.5
	elif [ $2 -eq 1 ]; then
		sudo docker run -i --rm -v $data_dir:/data:ro -v $outdir:/out poldracklab/mriqc:latest /data /out participant --fd_thres 0.5 --participant_label "${@:3}"
    elif [ $2 -eq 2 ]; then
		sudo docker run -i --rm -v $data_dir:/data:ro -v $outdir:/out poldracklab/mriqc:latest /data /out participant --fd_thres 0.5 --participant_label $3 --session-id $4
	fi
	if [ $1 -eq 2 ] && [ $# -gt 2 ] ; then
		sudo docker run -i --rm -v $data_dir:/data:ro -v $outdir:/out poldracklab/mriqc:latest /data /out group --fd_thres 0.5
	fi
fi
