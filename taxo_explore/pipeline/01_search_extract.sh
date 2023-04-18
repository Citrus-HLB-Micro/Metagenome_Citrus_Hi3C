#!/usr/bin/bash -l
#SBATCH -p short -c 48 --mem 96gb --out logs/search.log

module load hmmer/3.3-mpi
module load db-pfam
CPU=8
DBIN=db
SEARCH=search
ALNDIR=results
mkdir -p $ALNDIR $SEARCH

for DB in $(ls $DBIN/*.aa)
do
	NAME=$(basename $DB .aa)
	esl-sfetch --index $DB
	if [ ! -s $SEARCH/$NAME.domtbl ]; then
		srun hmmsearch --mpi --cut_ga --domtbl $SEARCH/$NAME.domtbl -o $SEARCH/$NAME.hmmer $PFAM_DB/Pfam-A.hmm $DB
	fi
	for HMM in MP RT_RNaseH RVT_1
	do
		grep "^$HMM" $SEARCH/$NAME.domtbl | awk '{print $4}' | esl-sfetch -f $DB - > $ALNDIR/$HMM.hits.aa
	done
done
