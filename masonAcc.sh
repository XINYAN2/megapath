#!/usr/bin/env bash
set -x

if [ "$#" -ne 2 ]; then
	echo "Usage $0 <xxx.id> <mason.fq>";
	exit 1;
fi

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=`dirname $SCRIPT`

set -x

# ${SCRIPT_PATH}/cc/masonAccuracy /nas3/dhli_1/0.megapath/viral_genome_diff_strain/acc2tid ${SCRIPT_PATH}/db/tax/nodes.dmp ${SCRIPT_PATH}/db/tax/names.dmp $1 $2
# ${SCRIPT_PATH}/cc/masonAccuracy /nas3/dhli_1/software/megapath/db/refseq/abcfhv.accession2taxid ${SCRIPT_PATH}/db/tax/nodes.dmp ${SCRIPT_PATH}/db/tax/names.dmp $1 $2
${SCRIPT_PATH}/cc/masonAccuracy /nas3/dhli_1/00.megapath.paper/0.metabench/paperSampled/taxid.acc2tid ${SCRIPT_PATH}/db/tax/nodes.dmp ${SCRIPT_PATH}/db/tax/names.dmp $1 $2
