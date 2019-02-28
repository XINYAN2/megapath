#!/usr/bin/env bash
set -x

if [ "$#" -lt 3 ]; then
	echo "Usage $0 1.fq 2.fq out_dir [skip_human=0] [assembly=0] [MegaBLAST=0]";
	exit 1;
fi

f1=$(readlink -f $1)
f2=$(readlink -f $2)

mkdir -p $3 && cd $3

# megapath
opt=-SM3
if [ ! -z $4 ] && [ $4 -eq 1 ]; then
	opt="${opt} -H"
fi

if [ ! -z $5 ] && [ $5 -eq 1 ]; then
	opt="${opt} -A"
fi

/nas3/dhli_1/software/megapath/runMegaPath.sh ${opt} -1 $f1 -2 $f2 -p m -t 24 >> m.log 2>&1

# # centrifuge
# D=/nas3/dhli_1/software/centrifuge
# export PATH=$D:$PATH
# CDB=/dev/shm/index64/c_abhv

# /usr/bin/time -v ${D}/centrifuge -p 24 -k 1 -x ${CDB} -1 m.bbduk_1.fq.gz -2 m.bbduk_2.fq.gz -S c.out --report-file c.creport 2> c.log
# centrifuge-kreport -x ${CDB} c.out > c.report

# # kraken
# KDB=/dev/shm/index64/k_abhv
# /usr/bin/time -v kraken --threads 24 --db ${KDB} --paired --fastq-input --gzip-compressed --output k.out  m.bbduk_1.fq.gz m.bbduk_2.fq.gz 2> k.log
# kraken-report --db ${KDB} k.out > k.report

# if [ ! -z $6 ] && [ $6 -eq 1 ]; then
# 	BDB=/dev/shm/index64/abhv.0
# 	/usr/bin/time -v sh -c "seqtk mergepe m.bbduk_[12].fq.gz | /nas3/dhli_1/utils/fastq2fasta.pl | blastn -num_threads 24 -outfmt 6 -evalue 1e-3 -db ${BDB} > b.m8" 2> b.log
# 	awk '{if ($12>=maxscore[$1]) { print; maxscore[$1] = $12 } }' b.m8 | /nas3/dhli_1/software/megapath/m8_to_lsam.pl | /nas3/dhli_1/software/megapath/cc/taxLookupAcc /nas3/dhli_1/software/megapath/db/refseq/abcfhv.accession2taxid /nas3/dhli_1/software/megapath/db/tax/nodes.dmp /nas3/dhli_1/software/megapath/db/tax/names.dmp - > b.lsam.id
# fi

# if [ ! -z $6 ] && [ $6 -eq 1 ]; then
# 	BDB=/dev/shm/index64/abhv.0
# 	/usr/bin/time -v sh -c "seqtk mergepe m.bbduk_[12].fq.gz | /nas3/dhli_1/utils/fastq2fasta.pl | blastn -task blastn -num_threads 24 -outfmt 6 -evalue 1e-5 -db ${BDB} > bn.m8" 2> bn.log
# 	awk '{if ($12>=maxscore[$1]) { print; maxscore[$1] = $12 } }' bn.m8 | /nas3/dhli_1/software/megapath/m8_to_lsam.pl | /nas3/dhli_1/software/megapath/cc/taxLookupAcc /nas3/dhli_1/software/megapath/db/refseq/abcfhv.accession2taxid /nas3/dhli_1/software/megapath/db/tax/nodes.dmp /nas3/dhli_1/software/megapath/db/tax/names.dmp - > bn.lsam.id
# fi


# if [ ! -z $6 ] && [ $6 -eq 1 ]; then
# 	BDB=/dev/shm/index64/abhv.0
# 	/usr/bin/time -v sh -c "seqtk mergepe m.bbduk_[12].fq.gz | /nas3/dhli_1/utils/fastq2fasta.pl | blastn -num_threads 24 -outfmt 6 -evalue 1e-5 -db ${BDB} -word_size 17 > b17.m8" 2> b17.log
# 	awk '{if ($12>=maxscore[$1]) { print; maxscore[$1] = $12 } }' b17.m8 | /nas3/dhli_1/software/megapath/m8_to_lsam.pl | /nas3/dhli_1/software/megapath/cc/taxLookupAcc /nas3/dhli_1/software/megapath/db/refseq/abcfhv.accession2taxid /nas3/dhli_1/software/megapath/db/tax/nodes.dmp /nas3/dhli_1/software/megapath/db/tax/names.dmp - > b17.lsam.id
# fi