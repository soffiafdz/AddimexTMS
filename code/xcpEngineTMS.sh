#! /bin/bash
## SGE batch file - xcpEngineTMS.SGE
#$ -S /bin/bash
## xcpEngineTMS is the jobname and can be changed
#$ -N xcpEngineTMS
## execute the job using the mpi_smp parallel enviroment and 122 cores per job
## create an array of 2 jobs the number of subjects and sessions
#$ -t 15-16
#$ -V
#$ -l mem_free=18G
#$ -pe openmp 12
## change the following working directory to a persistent directory that is
## available on all nodes, this is were messages printed by the app (stdout
## and stderr) will be stored
#$ -wd /mnt/MD1200B/egarza/sfernandezl/logs

## Modules
. /etc/profile.d/modules.sh
module load singularity/2.2

## Variables
HOME_DIR=/mnt/MD1200B/egarza/sfernandezl
OUT_DIR=${HOME_DIR}/AddimexTMS/derivatives/xcpOutput2
TMP_DIR=${HOME_DIR}/tmp
FMRIPREP_DIR=${HOME_DIR}/AddimexTMS/derivatives/fmriprep/output/fmriprep
SIMG=${HOME_DIR}/singImages/pennbbl_xcpengine-2019-04-19.img
FULL_COHORT=${HOME_DIR}/AddimexTMS/sourcedata/xcpEngine/cohorts/tmsFuncCohort.csv
PIPELINE=${HOME_DIR}/AddimexTMS/sourcedata/xcpEngine/designs/fc-36p_spkreg.dsn

## TMP cohort file with 1 line
HEADER=$(head -n 1 $FULL_COHORT)
LINE_N=$( expr $SGE_TASK_ID + 1 )
LINE=$(awk -v LINE_N=$(($SGE_TASK_ID + 1)) 'NR==LINE_N' $FULL_COHORT)
TMP_COHORT=${FULL_COHORT/tmsFuncCohort/tmpCohort-${SGE_TASK_ID}}
echo $HEADER > $TMP_COHORT 
echo $LINE >> $TMP_COHORT

# random sleep so that jobs dont start at _exactly_ the same time
sleep $(( $SGE_TASK_ID % 10 ))

singularity run -B /mnt:/mnt \
    $SIMG \
    -c $TMP_COHORT \
    -d $PIPELINE \
    -o $OUT_DIR \
    -r $FMRIPREP_DIR \
    -i $TMP_DIR
