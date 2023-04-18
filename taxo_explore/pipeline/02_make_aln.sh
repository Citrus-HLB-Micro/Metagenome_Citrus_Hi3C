#!/usr/bin/bash -l
#SBATCH -p short -c 2 --mem 8gb --out logs/aln.log

module load clipkit
module load hmmer
module load samtools
module load fasttree

DB=Artverviricota.aa
HMMFOLDER=HMM
ALNDIR=results
mkdir -p $ALNDIR
for hmm in $(ls ${HMMFOLDER}/*.hmm)
do
	marker=$(basename $hmm .hmm)
	hmmalign --amino -o ${ALNDIR}/${marker}.aa.msa ${HMMFOLDER}/${marker}.hmm $DB
	esl-reformat --replace=x:- --gapsym=- afa ${ALNDIR}/${marker}.aa.msa | perl -p -e 'if (! /^>/) { s/[ZBzbXx\*]/-/g }' > ${ALNDIR}/${marker}.aa.clnaln
	clipkit --log -m gappy -o $ALNDIR/${marker}.aa.clipkit ${ALNDIR}/${marker}.aa.clnaln
done
