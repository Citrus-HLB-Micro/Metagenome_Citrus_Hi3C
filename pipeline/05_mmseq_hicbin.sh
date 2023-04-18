#!/usr/bin/bash -l
#SBATCH -p short -N 1 -c 96 -n 1 --mem 256gb --out logs/taxo_clust_classify.%a.log

CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

module load mmseqs2
module load workspace/scratch
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
  N=$1
fi
if [ -z $N ]; then
  echo "cannot run without a number provided either cmdline or --array in sbatch"
  exit
fi
pushd hi3C

LIB=$(ls | sed -n ${N}p)

GENOME=$(realpath $LIB/bin3c_clust/all_binned.fasta)
if [ ! -f $GENOME ]; then
	cat $LIB/bin3c_clust/fasta/*.fna > $GENOME
fi
OUT=$LIB/bin3c_clust/all_binned_tax

DB2=/srv/projects/db/ncbi/mmseqs/uniref50
DB2NAME=$(basename $DB2)
mmseqs easy-taxonomy $GENOME $DB2 $OUT $SCRATCH --threads $CPU --lca-ranks kingdom,phylum,family  --tax-lineage 1
popd
