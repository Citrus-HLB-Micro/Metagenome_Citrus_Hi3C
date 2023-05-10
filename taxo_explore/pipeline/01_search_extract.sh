#!/usr/bin/bash -l
#SBATCH -p short -N 4 -n 8 --mem 96gb --out logs/search.log

module load hmmer/3.3.2-mpi
module load db-pfam
DBIN=db
SEARCH=search
ALNDIR=results
mkdir -p $ALNDIR $SEARCH

for DB in $(ls $DBIN/*.aa)
do
	NAME=$(basename $DB .aa)
	mkdir -p $ALNDIR/$NAME
	esl-sfetch --index $DB
	if [ ! -s $SEARCH/$NAME.domtbl ]; then
		mpirun hmmsearch --mpi --cut_ga --domtbl $SEARCH/$NAME.domtbl -o $SEARCH/$NAME.hmmer $PFAM_DB/Pfam-A.hmm $DB
	fi
	for HMM in MP RT_RNaseH RVT_1
	do
		grep -P "\s+$HMM\s+" $SEARCH/$NAME.domtbl | awk '{print $1}' | esl-sfetch -f $DB - > $ALNDIR/$NAME/$HMM.hits.aa
	done
done
