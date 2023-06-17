#!/bin/bash
post_gffread_fasta_file_paths=(
    "/ocean/projects/bio230007p/kelaba/data-v2/samples/SRR21563621/SRR21563621.fa"
    "/ocean/projects/bio230007p/kelaba/data-v2/samples/SRR21563622/SRR21563622.fa"
    "/ocean/projects/bio230007p/kelaba/data-v2/samples/SRR21563623/SRR21563623.fa"
    "/ocean/projects/bio230007p/kelaba/data-v2/samples/SRR21563624/SRR21563624.fa"
    "/ocean/projects/bio230007p/kelaba/data-v2/samples/SRR21563625/SRR21563625.fa"
)

blast_results=(
    "/ocean/projects/bio230007p/egaskin/tests-pipeline/sample0_test_outputs.txt"
    "/ocean/projects/bio230007p/egaskin/tests-pipeline/sample1_test_outputs.txt"
    "/ocean/projects/bio230007p/egaskin/tests-pipeline/sample2_test_outputs.txt"
    "/ocean/projects/bio230007p/egaskin/tests-pipeline/sample3_test_outputs.txt"
    "/ocean/projects/bio230007p/egaskin/tests-pipeline/sample4_test_outputs.txt"
)

declare -i sample_i

mkdir /ocean/projects/bio230007p/egaskin/tests-pipeline/temp-blast
cd /ocean/projects/bio230007p/egaskin/tests-pipeline/temp-blast
sample_i=0
for fasta_file_path in ${post_gffread_fasta_file_paths[@]}; do
    cur_result_path=${blast_results[${sample_i}]}

    # get all the IDs from the sample
    echo "Getting Unique IDs for sample $sample_i located at $fasta_file_path"
    cat $fasta_file_path | grep ">" | cut -d'>' -f2 |sort > unique-IDs-sample${sample_i}.txt

    # get all the IDs which had hits in the BLAST search (if using default, then e-value <= 0.01)
    echo "Getting Unique IDs for the BLAST results of $sample_i which are located at $cur_result_path"
    cut -d',' -f1 $cur_result_path | uniq | sort > unique-IDs-${sample_i}-results.txt

    number_insignificant_HSPs=$(comm -23 unique-IDs-sample${sample_i}.txt unique-IDs-${sample_i}-results.txt | wc -l)
    number_transcripts=$(wc -l unique-IDs-sample${sample_i}.txt)

    echo "For sample $sample_i, there were $number_transcripts transcripts submitted for BLASTn, and $number_insignificant_HSPs did not find an alignment in the database meeting the e-value cutoff"
    
    sample_i+=1
done

cd ..
rm -R /ocean/projects/bio230007p/egaskin/tests-pipeline/temp-blast