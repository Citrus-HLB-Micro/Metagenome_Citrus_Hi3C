#!/usr/bin/bash -l
#SBATCH -p short -c 2 --mem 8gb --out logs/aln.log

module load clipkit
module load hmmer
module load fasttree
HMMFOLDER=HMM
ALNDIR=results
for DB in $(ls $ALNDIR)
do
	for hmm in $(ls ${HMMFOLDER}/*.hmm)
	do
		marker=$(basename $hmm .hmm)
		hmmalign --amino -o ${ALNDIR}/$DB/${marker}.aa.msa ${HMMFOLDER}/${marker}.hmm $ALNDIR/$DB/$marker.hits.aa
		esl-reformat --replace=x:- --gapsym=- afa ${ALNDIR}/$DB/${marker}.aa.msa | perl -p -e 'if (! /^>/) { s/[ZBzbXx\*]/-/g }' > ${ALNDIR}/$DB/${marker}.aa.clnaln
		clipkit --log -m gappy -o $ALNDIR/$DB/${marker}.aa.clipkit ${ALNDIR}/$DB/${marker}.aa.clnaln
		FastTreeMP -gamma -lg $ALNDIR/$DB/${marker}.aa.clipkit > $ALNDIR/$DB/${marker}.aa.clipkit.tre
	done
done
