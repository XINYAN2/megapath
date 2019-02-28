#!/usr/bin/env bash

set -ex
set -m
set -o pipefail

SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname ${SCRIPT})

# configurations
MEGAHIT=/nas3/dhli_1/software/megahit/megahit
ACD=/nas3/dhli_1/software/ac-diamond-0.1-beta-linux64/ac-diamond
SOAP4=/nas3/dhli_1/soap4/soap4
HG_INI=/nas3/dhli_1/soap4/soap4-nt2.ini
NT_INI=/nas3/dhli_1/soap4/soap4-nt2.ini
HC_INI=/nas3/dhli_1/soap4/soap4-nt2.ini
RIBO_INI=/nas3/dhli_1/soap4/soap4-ribo.ini

TAX_LOOKUP=${SCRIPT_PATH}/cc/taxLookupAcc
DEINTERLEAVE=${SCRIPT_PATH}/cc/deinterleave
FASTQ2LSAM=${SCRIPT_PATH}/cc/fastq2lsam
GEN_COUNT_TB=${SCRIPT_PATH}/cc/genKrakenReport
M8_TO_LSAM=${SCRIPT_PATH}/m8_to_lsam.pl
SAM2CFQ=${SCRIPT_PATH}/cc/sam2cfq
reassign=${SCRIPT_PATH}/reassign.pl
FILTER_CROSS_FAMILY=${SCRIPT_PATH}/cc/filterCrossFamilyReads
EXTRACT_FROM_LSAM=${SCRIPT_PATH}/extractFromLSAM.pl
FQ2FA=${SCRIPT_PATH}/fastq2fasta.pl
CLEANUP=${SCRIPT_PATH}/cc/cleanup

BBMAP_DIR=/nas3/dhli_1/software/bbmap
BBNORM=${BBMAP_DIR}/bbnorm.sh
BBDUK=${BBMAP_DIR}/bbduk2.sh
BWA="bwa mem -M -B2 -O3 -E1 -h20"

DB=${SCRIPT_PATH}/db

export PATH=${SCRIPT_PATH}:${PATH}

# default parameters
PREFIX="megapath"
THREADS=24
NT_CUT_OFF=40
READ_LEN=150
MODE=0
MIN_LEN=50
ENTORPY=0.75
USE_BWA=false

while getopts "p:m1:2:t:c:L:d:M:B" option; do
	case "${option}" in
		p) PREFIX=${OPTARG};;
		1) READ1=${OPTARG};;
		2) READ2=${OPTARG};;
		m) MASK_HG=true;;
		t) THREADS=${OPTARG};; # not working with 4 & BBduk
		c) NT_CUT_OFF=${OPTARG};;
		L) READ_LEN=${OPTARG};;
		d) DB=${OPTARG};;
		M) MODE=${OPTARG};;
		B) USE_BWA=true;;
		*) exit 1;;
	esac
done

if [ ${READ_LEN} -le 50 ]; then
	MIN_LEN=30
	ENTORPY=0
fi

let "HG_CUT_OFF=READ_LEN*3/5";

if [ ${READ_LEN} -le 120 ]; then
	READ_LEN=121 # to activate SOAP4 long read mode
fi

if [ -z "${READ1}" ] || [ -z "${READ2}" ]; then
   echo "Usage: $0 -1 <read1.fq> -2 <read2.fq> [options]"
   echo "    -m  use masked human genome for host filtering"
   echo "    -p  output prefix [megapath]"
   echo "    -t  number of threads [24]"
   echo "    -c  NT alignment score cutoff [40]"
   echo "    -L  max read length [150]"
   echo "    -d  database directory [${SCRIPT_PATH}/db]"
   echo "    -M  mode: 0 (normal), 1 (dust-masked), 2 (dust-masked & removed BASV) [0], 3 (refSeq BAC+VIR)"
   echo "    -B  Use BWA-MEM (infers -M3)"
   exit 1
fi

SOAP_HG_IDX=${DB}/soap4-hg/human.maskViral.fna.index
SOAP_HGM_IDX=${DB}/soap4-hg/human.maskViral.fna.index
CLEANUP_IDX=${DB}/refseq/hc.ref.index
SOAP_NT_IDX=${DB}/soap4-nt-univec/nt_uv
SOAP_16S_IDX=${DB}/soap4-ribo/nt.16S.filtered.fasta.index
SOAP_18S_INDX=${DB}/soap4-ribo/nt.18_23_28S.filtered.fasta.index
ACD_NR=${DB}/ac-diamond-nr/nr2
BWA_IDX=${DB}/bwa/comb.fna.gz

if [ ${MODE} -eq 1 ]; then
	SOAP_NT_IDX=${DB}/soap4-nt-univec-1/nt_uv_dust_masked
elif [ ${MODE} -eq 2 ]; then
	SOAP_NT_IDX=${DB}/soap4-nt-univec-2/nt_uv_dust_masked_removed_BASV
	ACD_NR=${DB}/ac-diamond-nr-2/nr_removed_BASV
elif [ ${MODE} -eq 3 ]; then
	SOAP_NT_IDX=${DB}/refseq/abfv.ref
fi

# 0. preprocessing
if [ -e ${PREFIX}.prep.done ]; then
	echo "Skipping host filtering";
else
	echo "[TIMER] $(date) Running BBDuk to preprocess..."
	BBDUK_THREADS=$((${THREADS} / 2))
	if [ ${BBDUK_THREADS} -lt 1 ]; then
		BBDUK_THREADS=1
	fi

	${BBDUK} kmask=N qtrim=rl trimq=10 threads=${BBDUK_THREADS} minlength=${MIN_LEN} in=${READ1} in2=${READ2} out=stdout.fq ref=${BBMAP_DIR}/resources/adapters.fa hdist=1  | ${BBDUK} entropy=${ENTORPY} in=stdin.fq outm=${PREFIX}.low_compl.fq.gz threads=${BBDUK_THREADS} out=${PREFIX}.bbduk_1.fq.gz out2=${PREFIX}.bbduk_2.fq.gz

	echo "[TIMER] $(date) Running BBDuk to preprocess... Done"
	touch ${PREFIX}.prep.done
fi

if [ ${USE_BWA} ]; then
	echo "[TIMER] $(date) Running BWA..."
	${BWA} -t ${THREADS} ${BWA_IDX} ${PREFIX}.bbduk_1.fq.gz ${PREFIX}.bbduk_2.fq.gz > bwa.sam #| ${SAM2CFQ} -l | gzip -1 > ${PREFIX}.bwa.lsam.id.gz
	echo "[TIMER] $(date) Running BWA... Done."
	# echo "[TIMER] $(date) Generating count table..."
	# ${GEN_COUNT_TB} ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp ${PREFIX}.bwa.lsam.id.gz ${NT_CUT_OFF} > ${PREFIX}.bwa.report
	# echo "[TIMER] $(date) Generating count table... Done."
	exit 0;
fi

# 1. host filtering
if [ -e ${PREFIX}.host.done ]; then
	echo "Skipping host filtering";
else
	if [ ${MASK_HG} ]; then
		SOAP_HG_IDX=${SOAP_HGM_IDX};
	fi

	echo "[TIMER] $(date) Mapping reads to host by SOAP4..."
	${SOAP4} pair ${SOAP_HG_IDX} ${PREFIX}.bbduk_1.fq.gz ${PREFIX}.bbduk_2.fq.gz -o ${PREFIX}.dummy -C ${HG_INI} -L ${READ_LEN} -T ${THREADS} -u 750 -F -nc | ${FASTQ2LSAM} | ${EXTRACT_FROM_LSAM} -t ${HG_CUT_OFF} - | ${DEINTERLEAVE} ${PREFIX}.non_hg
	echo "[TIMER] $(date) Mapping reads to host by SOAP4... Done"

	if [ ! -s ${PREFIX}.non_hg.pe_1.fq ]; then
		echo "No reads remained after host filtering" >&2;
		exit 1;
	fi

	touch ${PREFIX}.host.done
fi

# 1.5 map to ribo
if [ -e ${PREFIX}.ribosome.done ] || [ ${MODE} -eq 3 ]; then
	echo "Skipping Ribo cleaning";
else
	echo "[TIMER] $(date) Mapping reads to 16S DB by SOAP4..."
	${SOAP4} pair ${SOAP_16S_IDX} ${PREFIX}.non_hg.pe_1.fq ${PREFIX}.non_hg.pe_2.fq -o ${PREFIX}.dummy -C ${RIBO_INI} -L ${READ_LEN} -T ${THREADS} -u 750 -F -P -nc | ${FASTQ2LSAM} | ${FILTER_CROSS_FAMILY} ${DB}/tax/16S.accession2taxid.gz ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp - | ${DEINTERLEAVE} ${PREFIX}.16S_filtered
	echo "[TIMER] $(date) Mapping reads to 16S DB by SOAP4... Done"

	echo "[TIMER] $(date) Mapping reads to 18,23,28S DB by SOAP4..."
	${SOAP4} pair ${SOAP_18S_INDX} ${PREFIX}.16S_filtered.pe_1.fq ${PREFIX}.16S_filtered.pe_2.fq -o ${PREFIX}.dummy -C ${RIBO_INI} -L ${READ_LEN} -T ${THREADS} -u 750 -F -P -nc | ${FASTQ2LSAM} | ${FILTER_CROSS_FAMILY} ${DB}/tax/18_23_28S.accession2taxid.gz ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp - | ${DEINTERLEAVE} ${PREFIX}.non_ribo
	echo "[TIMER] $(date) Mapping reads to 18,23,28S DB by SOAP4... Done"
	touch ${PREFIX}.ribosome.done
fi

# 2. map to NT
if [ -e ${PREFIX}.nt.done ]; then
	echo "Skipping NT mapping";
else
	echo "[TIMER] $(date) Mapping reads to NT by SOAP4..."
	i=0
	rm -f ${PREFIX}.nt.tmp_out.pe_1.fq ${PREFIX}.nt.tmp_out.pe_2.fq

	if [ ${MODE} -eq 3 ]; then
		NT_INPUT_1=${PREFIX}.non_hg.pe_1.fq
		NT_INPUT_2=${PREFIX}.non_hg.pe_2.fq
	else
		NT_INPUT_1=${PREFIX}.non_ribo.pe_1.fq
		NT_INPUT_2=${PREFIX}.non_ribo.pe_2.fq
	fi

	ln -s $(readlink -f ${NT_INPUT_1}) ${PREFIX}.nt.tmp_out.pe_1.fq
	ln -s $(readlink -f ${NT_INPUT_2}) ${PREFIX}.nt.tmp_out.pe_2.fq

	while [ -e ${SOAP_NT_IDX}.$i ]; do

		let "j=i+1"

		rm -f ${PREFIX}.nt.tmp_in_1.fq ${PREFIX}.nt.tmp_in_2.fq
		mv -f ${PREFIX}.nt.tmp_out.pe_1.fq ${PREFIX}.nt.tmp_in_1.fq
		mv -f ${PREFIX}.nt.tmp_out.pe_2.fq ${PREFIX}.nt.tmp_in_2.fq

		${SOAP4} pair ${SOAP_NT_IDX}.${i}.index ${PREFIX}.nt.tmp_in_1.fq ${PREFIX}.nt.tmp_in_2.fq -o ${PREFIX}.dummy -L ${READ_LEN} -T ${THREADS} -u 750 -F -C ${NT_INI} -top 95 | ${DEINTERLEAVE} ${PREFIX}.nt.tmp_out

		i=$j
	done

	rm -f ${PREFIX}.nt.tmp_in_1.fq ${PREFIX}.nt.tmp_in_2.fq
	mv -f ${PREFIX}.nt.tmp_out.pe_1.fq ${PREFIX}.nt.tmp_in_1.fq
	mv -f ${PREFIX}.nt.tmp_out.pe_2.fq ${PREFIX}.nt.tmp_in_2.fq

	${SOAP4} pair ${CLEANUP_IDX} ${PREFIX}.nt.tmp_in_1.fq ${PREFIX}.nt.tmp_in_2.fq -o ${PREFIX}.dummy -L ${READ_LEN} -T ${THREADS} -u 750 -F -C ${HC_INI} -top 95 | ${FASTQ2LSAM} | gzip -1 >${PREFIX}.nt.lsam.gz

	echo "[TIMER] $(date) Mapping reads to NT by SOAP4... Done"

	touch ${PREFIX}.nt.done
fi

# 3. Generate count-tables
if [ -e ${PREFIX}.count.done ]; then
	echo "Skipping NT counting";
else
	if [ ${MODE} -eq 3 ]; then
		ACC2TID=${DB}/refseq/abcfhv.accession2taxid
	else
		ACC2TID=${DB}/tax/nt_uv.accession2tax.gz
	fi

	echo "[TIMER] $(date) Looking up tax..."
	${TAX_LOOKUP} ${ACC2TID} ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp ${PREFIX}.nt.lsam.gz | gzip -1 > ${PREFIX}.nt.lsam.id.gz
	# ${CLEANUP} ${PREFIX}.nt.lsam.id.gz | gzip -1 > ${PREFIX}.nt.cleanup.lsam.id.gz
	${reassign} -t ${NT_CUT_OFF} ${PREFIX}.nt.lsam.id.gz | gzip -1 > ${PREFIX}.nt.ra.lsam.id.gz
	echo "[TIMER] $(date) Looking up tax... Done"

	echo "[TIMER] $(date) Generating count table..."
	# ${GEN_COUNT_TB} ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp ${PREFIX}.nt.lsam.id.gz ${NT_CUT_OFF} > ${PREFIX}.nt.report
	${GEN_COUNT_TB} ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp ${PREFIX}.nt.ra.lsam.id.gz ${NT_CUT_OFF} > ${PREFIX}.nt.ra.report
	echo "[TIMER] $(date) Generating count table... Done"

	touch ${PREFIX}.count.done
fi

# 4. Assembly of viral & unmapped reads
if [ -e ${PREFIX}.mgh.done ] || [ ${MODE} -eq 3 ]; then
	echo "Skipping Megahit assembly";
else
	echo "[TIMER] $(date) Extracting viral & ummapped reads..."
	${EXTRACT_FROM_LSAM} -t ${NT_CUT_OFF} -v ${PREFIX}.nt.lsam.id.gz | gzip -1 > ${PREFIX}.nt.viral.and.unmapped.fq.gz
	cat ${PREFIX}.low_compl.fq.gz >> ${PREFIX}.nt.viral.and.unmapped.fq.gz
	echo "[TIMER] $(date) Extracting viral & ummapped reads... Done"

	echo "[TIMER] $(date) BBNorm";
	${BBNORM} interleaved=true in=${PREFIX}.nt.viral.and.unmapped.fq.gz out=${PREFIX}.nt.viral.and.unmapped.bbnorm.fq.gz target=70 mindepth=1 threads=${THREADS}
	echo "[TIMER] $(date) BBNorm Done";

	echo "[TIMER] $(date) Assembly..."
	${MEGAHIT} -t ${THREADS} --min-count 1 --k-list 21,27,33,39,45,51,61,71,81,91,101,111,121 --12 ${PREFIX}.nt.viral.and.unmapped.bbnorm.fq.gz -o ${PREFIX}.mgh
	echo "[TIMER] $(date) Assembly... Done"

	touch ${PREFIX}.mgh.done
fi

# 4.1 map to contigs to NR
if [ -e ${PREFIX}.remap.done ] || [ ${MODE} -eq 3 ]; then
	echo "Skipping remap";
else
	echo "[TIMER] $(date) Mapping to contigs..."
	${SOAP4}-builder ${PREFIX}.mgh/final.contigs.fa
	${EXTRACT_FROM_LSAM} -t ${NT_CUT_OFF} -i ${PREFIX}.nt.lsam.gz | ${DEINTERLEAVE} ${PREFIX}.nt.unmapped
	${SOAP4} pair ${PREFIX}.mgh/final.contigs.fa.index ${PREFIX}.nt.unmapped.pe_1.fq ${PREFIX}.nt.unmapped.pe_2.fq -o ${PREFIX}.dummy -C ${NT_INI} -L ${READ_LEN} -T ${THREADS} -u 750 -F | ${FASTQ2LSAM} | gzip -1 > ${PREFIX}.r2c.lsam.gz
	rm -f ${PREFIX}.dummy.*
	${EXTRACT_FROM_LSAM} -t ${NT_CUT_OFF} -s -g ${PREFIX}.r2c.lsam.gz | ${FQ2FA} > ${PREFIX}.contig.unmap.fa
	sed 's/^>/>contig_/' ${PREFIX}.mgh/final.contigs.fa >> ${PREFIX}.contig.unmap.fa
	echo "[TIMER] $(date) Mapping to contigs... Done"

	echo "[TIMER] $(date) AC-DIAMOND to NR DB..."
	${ACD} blastx -p ${THREADS} -q ${PREFIX}.contig.unmap.fa -d ${ACD_NR} -a ${PREFIX}.nr --sensitive
	${ACD} view -a ${PREFIX}.nr.daa -o ${PREFIX}.nr.m8
	echo "[TIMER] $(date) AC-DIAMOND to NR DB... Done"

	echo "[TIMER] $(date) Taxa lookup..."
	${M8_TO_LSAM} ${PREFIX}.nr.m8 | gzip -1 > ${PREFIX}.nr.lsam.gz
	${TAX_LOOKUP} ${DB}/tax/prot.accession2taxid.gz ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp ${PREFIX}.nr.lsam.gz | gzip -1 > ${PREFIX}.nr.lsam.id.gz
	${SCRIPT_PATH}/r2c_to_r2g.pl ${PREFIX}.r2c.lsam.gz ${PREFIX}.nr.lsam.id.gz | gzip -1 > ${PREFIX}.nt.unmap.r2g.lsam.id.gz
	zcat ${PREFIX}.nr.lsam.id.gz ${PREFIX}.nt.unmap.r2g.lsam.id.gz | grep -v '^contig_' | ${GEN_COUNT_TB} ${DB}/tax/nodes.dmp ${DB}/tax/names.dmp - ${NT_CUT_OFF} > ${PREFIX}.nr.report
	echo "[TIMER] $(date) Taxa lookup... Done"

	touch ${PREFIX}.remap.done
fi