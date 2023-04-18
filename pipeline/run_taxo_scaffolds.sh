#!/usr/bin/bash -l
#SBATCH -p short -N 1 -c 96 -n 1 --mem 256gb --out taxo.log

CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

module load mmseqs2
module load workspace/scratch
ONE=$(ls *.fa | head -n 1)
DB2=/srv/projects/db/ncbi/mmseqs/uniref50
DB2NAME=$(basename $DB2)
mmseqs easy-taxonomy $ONE $DB2 mmseq_$DB2NAME $SCRATCH --threads $CPU --lca-ranks kingdom,phylum,family  --tax-lineage 1
