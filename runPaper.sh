set -x

# 1
# (cd 1.VirDiffStrand && /nas3/dhli_1/software/megapath/run3.sh pair_dat1.fq pair_dat2.fq paper 1 0 1 && echo "DONE 1")

# 0
# (cd 0.metabench && /nas3/dhli_1/software/megapath/run3.sh sampled_1.fq.gz sampled_2.fq.gz paperSampled 1 0 1 && echo "DONE 0")

# 2
# cd 2.500BAC
# for i in $(cut -f1 allall.txt); do
# 	if [ -f "$i"_1.fastq.gz ] && [ -f "$i"_2.fastq.gz ]; then
# 		f1=$(readlink -f "$i"_1.fastq.gz);
# 		f2=$(readlink -f "$i"_2.fastq.gz);
# 		(mkdir -p /dev/shm/$i && cd /dev/shm/$i && rm mp64* && /nas3/dhli_1/software/megapath/runMegaPath.sh -SHM3 -p m -1 $f1 -2 $f2 >log 2>&1 && rm -rf *.fq && echo "Done $i" && rm m.bbduk_[12].fq.gz m.low*.fq.gz);
# 	fi
# done

# 5
# (cd 5.hiv && /nas3/dhli_1/software/megapath/run3.sh SRR1106548_CGATGT_1.fastq.gz SRR1106548_CGATGT_2.fastq.gz paperC 1 1 && /nas3/dhli_1/software/megapath/run3.sh SRR1106548_G*_1.fastq.gz SRR1106548_G*_2.fastq.gz paperG && /nas3/dhli_1/software/megapath/run3.sh SRR1106548_T*_1.fastq.gz SRR1106548_T*_2.fastq.gz paperT && echo "DONE 5")

# # 3
# (cd 3.D68 && /nas3/dhli_1/software/megapath/run3.sh merged_1.fastq.gz merged_2.fastq.gz paperMerged 1 1 && /nas3/dhli_1/software/megapath/run3.sh SRR1919637_1.fastq.gz SRR1919637_2.fastq.gz paper637 1 1 && echo "DONE 3")

# # 6
# (cd 6.basv && /nas3/dhli_1/software/megapath/run3.sh SRR533978_1.fastq.gz SRR533978_2.fastq.gz paper 1 1 && echo "DONE 6")

# # 4

# (cd 4.liver && /nas3/dhli_1/software/megapath/run3.sh ERR205979_1.fastq.gz ERR205979_2.fastq.gz paper79 0 1 && /nas3/dhli_1/software/megapath/run3.sh ERR205980_1.fastq.gz ERR205980_2.fastq.gz paper80 0 1 && /nas3/dhli_1/software/megapath/run3.sh ERR205981_1.fastq.gz ERR205981_2.fastq.gz paper81 0 1 && /nas3/dhli_1/software/megapath/run3.sh ERR205982_1.fastq.gz ERR205982_2.fastq.gz paper82 0 1 && echo "DONE 4")

cd 2.500BAC
BDB=/dev/shm/index64/abhv.0

for i in $(cut -f1 allall.txt); do
	if [ ! -f /dev/shm/$i/bn.lsam.id ] && [ -f "$i"_1.fastq.gz ] && [ -f "$i"_2.fastq.gz ]; then
		f1=$(readlink -f "$i"_1.fastq.gz);
		f2=$(readlink -f "$i"_2.fastq.gz);
		(mkdir -p /dev/shm/$i && cd /dev/shm/$i && rm -f m.prep.done && rm -f *.fq.gz && /nas3/dhli_1/software/megapath/runMegaPath.sh -SHM3 -p m -1 $f1 -2 $f2 && seqtk sample m.bbduk_1.fq.gz 500 | awk '{if(NR%4==1){$1=$1"/1"} print}'> 500_1.fq && seqtk sample m.bbduk_2.fq.gz 500 | awk '{if(NR%4==1){$1=$1"/2"} print}' > 500_2.fq && /usr/bin/time -v sh -c "seqtk mergepe 500_[12].fq | /nas3/dhli_1/utils/fastq2fasta.pl | blastn -num_threads 24 -outfmt 6 -evalue 1e-5 -db ${BDB} -task blastn > bn.m8" 2> bn.log && awk '{if ($12>=maxscore[$1]) { print; maxscore[$1] = $12 } }' bn.m8 > bn.best.m8 && rm bn.m8 && /nas3/dhli_1/software/megapath/m8_to_lsam.pl bn.best.m8 | /nas3/dhli_1/software/megapath/cc/taxLookupAcc /nas3/dhli_1/software/megapath/db/refseq/abcfhv.accession2taxid /nas3/dhli_1/software/megapath/db/tax/nodes.dmp /nas3/dhli_1/software/megapath/db/tax/names.dmp - > bn.lsam.id && /nas3/dhli_1/software/megapath/cc/genKrakenReport /nas3/dhli_1/software/megapath/db/tax/nodes.dmp /nas3/dhli_1/software/megapath/db/tax/names.dmp bn.lsam.id > bn.report && echo "DONE $i" && rm *.fq.gz);
	fi
done