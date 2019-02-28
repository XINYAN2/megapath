# Chun please change the path of SOAP4 and the output prefix
SOAP4=/nas3/dhli_1/software/soap4/soap4
OUTPUT_PREFIX=soap4 # will output OUTPUT_PREFIX.merged.bam, OUTPUT_PREFIX.lsam, OUTPUT_PREFIX.lsam.labels, OUTPUT_PREFIX.stat

INDEX=/nas3/dhli_1/0.megapath/3.test/fastqsim/ref.diff.strain.fasta.index
R1=/nas3/dhli_1/0.megapath/3.test/fastqsim/SRR2146185.fastq
R2=/nas3/dhli_1/0.megapath/3.test/fastqsim/dummy_pe2.fq.gz
LEN=151

export PATH=/nas3/dhli_1/software/megapath:$PATH

# Run SOAP4
${SOAP4} pair ${INDEX} ${R1} ${R1} -o ${OUTPUT_PREFIX} -b 3 -L ${LEN}
# Merge results
samtools cat ${OUTPUT_PREFIX}.gout.* ${OUTPUT_PREFIX}.dpout.* ${OUTPUT_PREFIX}.unpair > ${OUTPUT_PREFIX}.merged.bam
# remove unnecessary files
rm ${OUTPUT_PREFIX}.gout.* ${OUTPUT_PREFIX}.dpout.* ${OUTPUT_PREFIX}.unpair
# bam -> lsam
sam2cfq.pl -l ${OUTPUT_PREFIX}.merged.bam | awk 'and($2, 0x40)!= 0 && $3>0' > ${OUTPUT_PREFIX}.lsam
# lsam -> labels
/nas3/dhli_1/software/megapath/cc/taxaLookup /nas3/dhli_1/software/megapath/db/taxa/gi_taxid_nucl.dmp /nas3/dhli_1/software/megapath/db/taxa/nodes.dmp /nas3/dhli_1/software/megapath/db/taxa/names.dmp ${OUTPUT_PREFIX}.lsam > ${OUTPUT_PREFIX}.lsam.labels
# calcAccuracy
calcAccuracy.pl ${R1} ${OUTPUT_PREFIX}.lsam.labels | tee ${OUTPUT_PREFIX}.stat