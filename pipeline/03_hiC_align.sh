#!/usr/bin/bash -l
#SBATCH -p short -c 128 -N 1 --mem 200gb --out logs/hicAlign.%a.log 

module load samtools
module load bwa
INPUTDATA=input
INDIR=results_prefastp
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
  GENOME=$INDIR/$STRAIN/scaffolds/${STRAIN}_R.fa
  TARGET=$OUTDIR/$STRAIN
  mkdir -p $TARGET
  TARGETG=$TARGET/$STRAIN.fasta.gz
  if [ ! -s $TARGETG ]; then
  	bgzip -c $GENOME > $TARGETG
  fi
  if [ ! -s $TARGETG.amb ]; then
  	bwa index $TARGETG
  fi
  if [ ! -f $TARGET/${STRAIN}_hic2ctg.bam ]; then
  	paircount=1
	for pair in $(echo -n $PROXIMA | perl -p -e 's/;/,/g');
  	do
		echo "pair is $pair paircount is $paircount"
		if [ ! -f $TARGET/${STRAIN}_hic2ctg_${paircount}.bam ]; then
			bwa mem -t $CPU -5SP $TARGETG $INPUTDATA/proxima/$pair | \
				samtools view -bS --threads 4 -O BAM -F 0x904 - | \
				samtools sort -n --threads 8 -m 8G -T $SCRATCH/$STRAIN.hic${paircount} -o $TARGET/${STRAIN}_hic2ctg_${paircount}.bam
		fi
		paircount=$(expr $paircount + 1)
	done
	samtools merge -n -o $TARGET/${STRAIN}_hic2ctg.bam $TARGET/${STRAIN}_hic2ctg_?.bam
  fi
done
