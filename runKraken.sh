#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
	echo "Usage $0 1.fq 2.fq";
	exit 1;
fi

DB=/nas3/dhli_1/0.megapath/refseq20161118/kraken_db

/usr/bin/time -v kraken --preload --threads 24 --db ${DB} --paired --fastq-input --gzip-compressed --output k.out $1 $2 2> k.log

kraken-report --db ${DB} k.out > k.report