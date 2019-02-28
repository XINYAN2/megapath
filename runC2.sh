#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
	echo "Usage $0 1.fq 2.fq";
	exit 1;
fi

D=/nas3/dhli_1/software/centrifuge
# ${D}/centrifuge -k 1 -x ${D}/indices/nt/nt -1 $1 -2 $2 -S centrifugek1.out --report-file centrifugek1.report
# cut -f1,3 centrifugek1.out > centrifugek1.id

# ${D}/centrifuge -p 24 -k 1 -x ${D}/indices/b+h+v/b+h+v -1 $1 -2 $2 -S centrifugek1refSeq.out --report-file centrifugek1refSeq.report
# cut -f1,3 centrifugek1refSeq.out > centrifugek1refSeq.id

export PATH=$D:$PATH
# DB=/nas3/dhli_1/0.megapath/refseq20161118/abcfhv
DB=/dev/shm/index64/c_abhv

/usr/bin/time -v ${D}/centrifuge -p 2 -k 1 -x ${DB} -1 $1 -2 $2 -S c.out --report-file c.creport 2> c.log

centrifuge-kreport -x ${DB} c.out > c.report