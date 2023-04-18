#!/usr/bin/bash -l
#SBATCH -p short -C ryzen -N 1 -n 1 -c 4 --mem 48gb --out logs/fastp.%a.log

module load fastp

module load workspace/scratch
INPUT=input/shotgun
SAMPFILE=samples.csv
WORK=working
mkdir -p $WORK
CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
  N=$1
fi
if [ -z $N ]; then
  echo "cannot run without a number provided either cmdline or --array in sbatch"
  exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read STRAIN SHOTGUN PROXIMA
do
	mkdir -p $WORK/$STRAIN
  for BASEPATTERN in $(echo -n $SHOTGUN | perl -p -e 's/\;/,/g');
  do
      echo $BASEPATTERN
      unset IFS
      r=1
      for file in $(ls $INPUT/$BASEPATTERN)
      do
	cat $file >> $SCRATCH/${STRAIN}_R${r}.fastq.gz
	r=$(expr 2 - $r + 1)
      done
      IFS=,
  done
      fastp -w $CPU --detect_adapter_for_pe -j logs/$STRAIN.LIB${LIB}.json -h logs/$STRAIN.LIB${LIB}.html \
	      -i $SCRATCH/${STRAIN}_R1.fastq.gz -I $SCRATCH/${STRAIN}_R2.fastq.gz -o $WORK/$STRAIN/${STRAIN}_R1.fq.gz --out2 $WORK/$STRAIN/${STRAIN}_R2.fq.gz \
	      --unpaired1 $WORK/$STRAIN/${STRAIN}_unpair1.fq.gz --unpaired2 $WORK/$STRAIN/${STRAIN}_unpair2.fq.gz --overrepresentation_analysis
done


