#!/bin/bash
#SBATCH -p RM-shared
#SBATCH -t 03:00:00
#SBATCH --ntasks-per-node=64
##source ~/.bashrc

eval "$(conda shell.bash hook)"
conda env create -f env.yml -n project_2
conda activate project_2

#blast db
wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.13.0/ncbi-blast-2.13.0+-x64-linux.tar.gz
mkdir refseq_rna 
perl ncbi-blast-2.13.0+/bin/update_blastdb.pl --decompress refseq_rna

#gnu parallel
wget https://ftp.gnu.org/gnu/parallel/parallel-latest.tar.bz2
cd parallel-20230422
./configure && make

#move tars out of the way
mkdir installation_tars
mv ncbi-blast-2.13.0+-x64-linux.tar.gz installation_tars/
mv parallel-latest.tar.bz2 installation_tars

