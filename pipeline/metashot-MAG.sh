#!/usr/bin/bash -l
#SBATCH -p intel -N 1 -n 32 --mem 192gb --out logs/mag.%a.log --time 72:00:00

module load singularity
module load workspace/scratch
INPUT=input/shotgun
SAMPFILE=samples.csv
export NXF_SINGULARITY_CACHEDIR=/bigdata/stajichlab/shared/singularity_cache/
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
  PREFIX=$STRAIN
  O=$SCRATCH/${STRAIN}_R{1,2}.fastq.gz
  rm -f $SCRATCH/${STRAIN}_R{1,2}.fastq.gz
  for BASEPATTERN in $(echo -n $SHOTGUN | perl -p -e 's/\;/,/g');
  do
      echo $BASEPATTERN
      r=1
      unset IFS
      for file in $(ls $INPUT/$BASEPATTERN)
      do
	echo "cat $file >> $SCRATCH/${STRAIN}_R${r}.fastq.gz"
	r=$(expr 2 - $r + 1);
      done
      IFS=,
  done
  
  echo "O is $O"
  ./nextflow run metashot/mag-illumina \
	     --reads "$O" \
	     --outdir results/$STRAIN --max_cpus $CPU \
	     --scratch $SCRATCH -c metashot-MAG.cfg
done

