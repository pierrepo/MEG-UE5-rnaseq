#! /usr/bin/env bash

# Good practice: stop script at first error.
set -euo pipefail

# Define log filename.
# The $0 variable contains the name of the script.
logfile="${0%.sh}_$(date +'%Y%m%d-%H%M%S').log"
echo "Log file is: ${logfile}"

# The tee command prints to stdout and to a file.
echo "Running $0 for user ${USER} on computer ${HOSTNAME}" | tee -a "${logfile}"

# Collect info from available data and software.
echo "#=====================================================================" | tee -a "${logfile}"
echo "# 0. Data & software                                                  " | tee -a "${logfile}"
echo "#=====================================================================" | tee -a "${logfile}"

# Initial data.
echo "Initial data to work with:" | tee -a "${logfile}"

# The tree command shows files and directories in a tree-like structure.
# The --du -h options give size of individual files.
tree --du -h chr6p_samples/ chr6p_genomes/ chr6p_annotations/ | tee -a "${logfile}"

# The du command shows the disk usage of directories.
du -csh chr6p_samples/ chr6p_genomes/ chr6p_annotations/ | tee -a "${logfile}"

# Software.
echo ""
echo "Software (name and version):" | tee -a "${logfile}"
echo "trimmomatic version:" | tee -a "${logfile}"
trimmomatic -version | tee -a "${logfile}"
echo "hisat2 version:" | tee -a "${logfile}"
hisat2 --version | head -n 1 | tee -a "${logfile}"
echo "samtools version:" | tee -a "${logfile}"
samtools --version | head -n 1 | tee -a "${logfile}"


# Trim / clean samples.
# GUP-1 for PGF samples
# GUP-3 for COX samples
echo "#=====================================================================" | tee -a "${logfile}"
echo "# 1. trim/clean samples                                               " | tee -a "${logfile}"
echo "#=====================================================================" | tee -a "${logfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"

# Define sample directory.
sample_dir="chr6p_samples"

# Create directory to store trimmed fastq files.
trim_dir="chr6p_trim"
mkdir -p ${trim_dir}

for sample_name in GUP-1_6p GUP-3_6p
do
	echo "Trim sample ${sample_name}" | tee -a "${logfile}"
	trimmomatic PE -threads 2 \
		${sample_dir}/${sample_name}_R1.fastq.gz \
		${sample_dir}/${sample_name}_R2.fastq.gz \
		-baseout ${trim_dir}/${sample_name}_trim.fastq.gz \
		ILLUMINACLIP:${CONDA_PREFIX}/share/trimmomatic/adapters/TruSeq3-PE-2.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
done

# After trimming we keep only 'paired' reads: *P.fastq.gz

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"


# Index reference genomes.
echo "#=====================================================================" | tee -a "${logfile}"
echo "# 2. index reference genomes                                          " | tee -a "${logfile}"
echo "#=====================================================================" | tee -a "${logfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"

# chr6p-pgf is the genome for the PGF haplotype (reference for CMH)
# chr6p-cox is the genome for the COX haplotype

# Define genome directory.
genome_dir="chr6p_genomes"

# Create directory for store genome indexes.
index_dir="chr6p_index"
mkdir -p ${index_dir}

# Copy genomes.
cp ${genome_dir}/*.fa ${index_dir}

# Index genomes.
for genome_name in chr6p-pgf chr6p-cox
do
    echo "Build index for genome ${genome_name}" | tee -a "${logfile}"
	hisat2-build ${index_dir}/${genome_name}.fa ${index_dir}/${genome_name}
done

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"


# Map samples on reference genomes.
echo "#=====================================================================" | tee -a "${logfile}"
echo "# 3. map samples on genome + index mapping                            " | tee -a "${logfile}"
echo "#=====================================================================" | tee -a "${logfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"

# Create directory to store mapping results.
map_dir="chr6p_map"
mkdir -p ${map_dir}

# Go into ${map_dir}
cd ${map_dir}

for genome_name in chr6p-pgf chr6p-cox
do
	for sample_name in GUP-1_6p GUP-3_6p
	do
    	echo "map sample ${sample_name} on genome ${genome_name}" | tee -a "../${logfile}"
    	hisat2 -x ../${index_dir}/${genome_name} \
        	--rna-strandness FR \
        	-1 ../${trim_dir}/${sample_name}_trim_1P.fastq.gz \
        	-2 ../${trim_dir}/${sample_name}_trim_2P.fastq.gz \
        	2> ${sample_name}_on_${genome_name}.log | \
        	samtools sort -T ${sample_name}_on_${genome_name} -o ${sample_name}_on_${genome_name}.bam -
    	# --rna-strandness FR: to specify the forward strand (FR) that is sequenced in this RNASEq library
    	# Log file produced by hisat2 contains counts of mapped and unmapped reads

		# Samtools indexes mapped reads.
	    samtools index -b ${sample_name}_on_${genome_name}.bam
    	mv "${sample_name}_on_${genome_name}.bam.bai" "${sample_name}_on_${genome_name}.bai"
	done
done

cd ..

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"


# Count mapped reads.
echo "#===================================================================== " | tee -a "${logfile}"
echo "# 4. count number of mapped reads (with and without mismatches)        " | tee -a "${logfile}"
echo "#===================================================================== " | tee -a "${logfile}"
echo "start: $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"

# Go into ${map_dir}
cd ${map_dir}

echo "Sample   on genome   :  total_reads no_mismatch_reads percentage" | tee -a "../${logfile}"
for sample_name in GUP-1_6p GUP-3_6p
do
    for genome_name in chr6p-pgf chr6p-cox
    do
    	total_reads=$(samtools view ${sample_name}_on_${genome_name}.bam ${genome_name}:28734408-33383765 | uniq | wc -l)
    	nomismatch_reads=$(samtools view ${sample_name}_on_${genome_name}.bam ${genome_name}:28734408-33383765 | grep "NM:i:0" | uniq | wc -l)
    	percentage=$(echo "scale=3; ${nomismatch_reads}/${total_reads}*100" | bc -l)
    	echo "${sample_name} on ${genome_name}:  ${total_reads} ${nomismatch_reads} ${percentage}" | tee -a "../${logfile}"
    done
done

cd ..

echo "end  : $(date +'%Y-%m-%d %H:%M:%S')" | tee -a "${logfile}"


# Final statement on data.
echo "#===================================================================== " | tee -a "${logfile}"
echo "# Size of data: initial and generated                                            " | tee -a "${logfile}"
echo "#===================================================================== " | tee -a "${logfile}"
du -csh chr6p_*/ | tee -a "${logfile}"


echo "Well done!" | tee -a "${logfile}"
