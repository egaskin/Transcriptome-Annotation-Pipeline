#!/bin/bash
#SBATCH -p RM-shared
#SBATCH -t 03:00:00
#SBATCH --ntasks-per-node=64
##source ~/.bashrc

eval "$(conda shell.bash hook)"
conda activate project_2

#prettier error messages
set -e
set -u
set -o pipefail


cwd=$(pwd)
sample_dir=${1}
REF_ANNOTATION=$cwd/${2}
REF_FA=$cwd/${3}

#bowtie build before alignment
bowtie2-build ${REF_FA} full

#Loop through each directory and run alignemnt
for dir in "$cwd/$sample_dir"*/; do
    sample=$(basename "$dir")
    #alignment start
    bowtie2 -x ${cwd}/full -q --interleaved ${dir}${sample}.fastq -S ${dir}${sample}.sam

    #postprocessing
    samtools view -S -b ${dir}${sample}.sam > ${dir}${sample}_full.bam
    samtools sort ${dir}${sample}_full.bam -o ${dir}${sample}_sorted.bam
    samtools index ${dir}${sample}_sorted.bam

    # rm ${dir}${sample}_full.bam
    # rm ${dir}${sample}.sam

done

# echo finished bowtie2 and samtools aligning to reference genome

#stringtie to get gtfs
for dir in "$cwd/$sample_dir"*/; do
    sample=$(basename "$dir")

    # Define the input BAM file path
    BAM_FILE=${dir}${sample}_sorted.bam
    # Define the output GTF file path
    OUTPUT_FILE=${dir}${sample}.gtf

    # Run StringTie to assemble and quantify transcripts
    if [ -f "$REF_ANNOTATION" ]; then
        stringtie $BAM_FILE -o $OUTPUT_FILE -G $REF_ANNOTATION
    else
        stringtie $BAM_FILE -o $OUTPUT_FILE
    fi

    # #convert gtf to fa
    OUT_FA=${dir}${sample}.fa
    OUT_FQ=${dir}${sample}.fq

    TRANSCRIPT=${dir}${sample}.gtf

    gffread -w $OUT_FA -g $REF_FA $TRANSCRIPT

    #convert fa to fq - use BBMap
    reformat.sh in=$OUT_FA out=$OUT_FQ
done

# echo finished running stringtie and converting to fasta format

#blast start
database_path=${cwd}/${4}
blast_algorithm_path=${cwd}/${5}

echo $database_path, $blast_algorithm_path

if [ ! -d "blast_outputs" ]; then
    mkdir blast_outputs
fi
outdir="blast_outputs"

very_start=`date +%s`
for dir in "$cwd/$sample_dir"*/; do
    sample=$(basename "$dir")

    FA_FILE=${dir}${sample}.fa

    start=`date +%s`
    echo "Performing parallel BLASTn for sample $sample located at $FA_FILE"
    cat $FA_FILE | parallel --block 100k --recstart '>' --pipe $blast_algorithm_path -evalue 0.01 -outfmt 10 -db $database_path -query - > $outdir"/${sample}_test_outputs.txt"
    
    end=`date +%s`
    runtime=$((end-start))
    echo "Completed the submission of BLASTn for sample $sample which took $runtime seconds"
done

runtime=$((end-very_start))
echo "Blast Script completed! Blasting took $runtime total seconds"


#Augustus start
if [ ! -d "augustus_outputs" ]; then
    mkdir augustus_outputs
fi

OUT_AUG='augustus_outputs'

for dir in "$cwd/$sample_dir"*/; do
    sample=$(basename "$dir")

    FA_FILE=${dir}${sample}.fa
    augustus --species=chicken --outfile=${OUT_AUG}/${sample}.gtf $FA_FILE
done

# echo finished running Augustus
# echo pipeline finished