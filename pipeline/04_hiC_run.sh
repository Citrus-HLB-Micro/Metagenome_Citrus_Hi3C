#!/usr/bin/bash -l
#SBATCH -p short -N 1 -c 2 --mem 48gb --out logs/hicbin.%a.log 

module load bin3C
module load workspace/scratch

INPUTDATA=input
OUTDIR=hi3C
SAMPFILE=samples.csv

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
  TARGET=$OUTDIR/$STRAIN
  GENOME=$TARGET/$STRAIN.fasta.gz
  BAM=$TARGET/${STRAIN}_hic2ctg.bam
  if [ ! -f $BAM ]; then
	  echo "need to have run the alignment step first - no $BAM"
	  exit
  fi
  if [ ! -f $TARGET/bin3c_out/contact_map.p.gz ]; then
  	bin3C.py mkmap -e MluCI -e Sau3AI -v $GENOME $BAM $TARGET/bin3c_out
  fi
  if [ ! -d $TARGET/bin3c_clust ]; then
  	bin3C.py cluster -v $TARGET/bin3c_out/contact_map.p.gz $TARGET/bin3c_clust
  fi
done


