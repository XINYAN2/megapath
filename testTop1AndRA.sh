set -e

D=/nas3/dhli_1/software/megapath

${D}/cc/taxLookupAcc ${D}/db/tax/nt_uv.accession2tax.gz ${D}/db/tax/nodes.dmp ${D}/db/tax/names.dmp megapath.nt.lsam 1 > megapath.nt.id
${D}/cc/taxLookupAcc ${D}/db/tax/nt_uv.accession2tax.gz ${D}/db/tax/nodes.dmp ${D}/db/tax/names.dmp megapath.nt.lsam 1 1 > megapath.nt.top1.id
${D}/deMulti.pl megapath.nt.id > megapath.nt.dm.id
${D}/deMulti.pl megapath.nt.top1.id > megapath.nt.top1.dm.id

echo "Top 1:"
cut -f1,6 megapath.nt.top1.id | ${D}/cc/masonAccuracy ${D}/db/tax/for_mason.accession2tax.gz ${D}/db/tax/nodes.dmp ${D}/db/tax/names.dmp - ../*_1.fq
echo "Reassignment:"
cut -f1,6 megapath.nt.dm.id | ${D}/cc/masonAccuracy ${D}/db/tax/for_mason.accession2tax.gz ${D}/db/tax/nodes.dmp ${D}/db/tax/names.dmp - ../*_1.fq
echo "Top1 + Reassignment:"
cut -f1,6 megapath.nt.top1.dm.id | ${D}/cc/masonAccuracy ${D}/db/tax/for_mason.accession2tax.gz ${D}/db/tax/nodes.dmp ${D}/db/tax/names.dmp - ../*_1.fq