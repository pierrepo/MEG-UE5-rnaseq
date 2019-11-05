#! /usr/bin/env bash

# stop script at first error
set -euo pipefail

# define output filename
outfile="${0%.sh}_$(date +'%Y%m%d-%H%M%S').log"
echo "Log file is: ${outfile}"


echo "Running $0 for ${USER} on ${HOSTNAME}" | tee -a "${outfile}"
echo "#=====================================================================" | tee -a "${outfile}"
echo "# 0. Software                                                         " | tee -a "${outfile}"
echo "#=====================================================================" | tee -a "${outfile}"
echo "trimmomatic version:" | tee -a "${outfile}"
trimmomatic -version | tee -a "${outfile}"
echo "hisat2 version:" | tee -a "${outfile}"
hisat2 --version | head -n 1 | tee -a "${outfile}"
echo "samtools version:" | tee -a "${outfile}"
samtools --version | head -n 1 | tee -a "${outfile}"


# trimming / cleaning data
# GUP-1 for PGF samples
# GUP-3 for COX samples
echo "#=====================================================================" | tee -a "${outfile}"
echo "# 1. trim/clean samples                                               " | tee -a "${outfile}"
echo "#=====================================================================" | tee -a "${outfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${outfile}"

# define sample name
sample_name="GUP-1_6p"

# define sample dir
sample_dir="chr6p_samples"

# create directory for trimming results
trim_dir="chr6p_trim"
mkdir -p ${trim_dir}

trimmomatic PE -threads 2 \
    ${sample_dir}/${sample_name}_R1.fastq.gz \
    ${sample_dir}/${sample_name}_R2.fastq.gz \
    -baseout ${trim_dir}/${sample_name}_trim.fastq.gz \
    ILLUMINACLIP:${CONDA_PREFIX}/share/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

# after trimming we keep only 'paired' reads: *P.fastq.gz

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${outfile}"


# indexing reference genomes
echo "#=====================================================================" | tee -a "${outfile}"
echo "# 2. index reference genomes                                          " | tee -a "${outfile}"
echo "#=====================================================================" | tee -a "${outfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${outfile}"

# chr6p-pgf is the genome for the PGF haplotype (reference for CMH)
# chr6p-cox is the genome for the COX haplotype

# define genome dir
genome_dir="chr6p_genomes"

# create directory for indexing results
index_dir="chr6p_index"
mkdir -p ${index_dir}

# copy genomes
cp ${genome_dir}/*.fa ${index_dir}

# index genomes
for genome_name in chr6p-pgf chr6p-cox
do
    hisat2-build ${index_dir}/${genome_name}.fa ${index_dir}/${genome_name}
done

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${outfile}"


# map samples on reference genomes
echo "#=====================================================================" | tee -a "${outfile}"
echo "# 3. map samples on genome + index maping                             " | tee -a "${outfile}"
echo "#=====================================================================" | tee -a "${outfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${outfile}"

# create directory for mapping results
map_dir="chr6p_map"
mkdir -p ${map_dir}

# go into ${map_dir}
cd ${map_dir}

# define sample name
sample_name="GUP-1_6p"

for genome_name in chr6p-pgf chr6p-cox
do
    echo "map ${sample_name} on ${genome_name}"
    hisat2 -x ../${index_dir}/${genome_name} \
        --rna-strandness FR \
        -1 ../${trim_dir}/${sample_name}_trim_1P.fastq.gz \
        -2 ../${trim_dir}/${sample_name}_trim_2P.fastq.gz \
        2> ${sample_name}_on_${genome_name}.log | \
        samtools sort -T ${sample_name}_on_${genome_name} -o ${sample_name}_on_${genome_name}.bam -
    # --rna-strandness FR: to specify the forward strand (FR) that is sequenced in this RNASEq library
    # log file contains counts of mapped and unmapped reads

    samtools index -b ${sample_name}_on_${genome_name}.bam
    mv ${sample_name}_on_${genome_name}.bam.bai ${sample_name}_on_${genome_name}.bai
done

cd ..

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${outfile}"


# map samples on reference genomes
echo "#===================================================================== " | tee -a "${outfile}"
echo "# 4. count number of mapped reads (with and without mismatches)        " | tee -a "${outfile}"
echo "#===================================================================== " | tee -a "${outfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${outfile}"

# go into ${map_dir}
cd ${map_dir}

# define sample name
sample_name="GUP-1_6p"

echo "Sample   on genome   :  total_reads no_mismatch_reads percentage" | tee -a "../${outfile}"
for genome_name in chr6p-pgf chr6p-cox
do
    total_reads=$(samtools view ${sample_name}_on_${genome_name}.bam ${genome_name}:28734408-33383765 | uniq | wc -l)
    nomismatch_reads=$(samtools view ${sample_name}_on_${genome_name}.bam ${genome_name}:28734408-33383765 | grep "NM:i:0" | uniq | wc -l)
    percentage=$(echo "scale=3; ${nomismatch_reads}/${total_reads}*100" | bc -l)
    echo "${sample_name} on ${genome_name}:  ${total_reads} ${nomismatch_reads} ${percentage}" | tee -a "../${outfile}"
done

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "../${outfile}"

cd ..


echo "Well done!" | tee -a "${outfile}"
