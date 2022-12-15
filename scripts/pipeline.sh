###RNA DECONTAMINATION PIPELINE BY José Manuel Muñoz###

echo -e "\n\n### Pipeline started at $(date +'%H:%M:%S') ###\n\n"

#Run cleanup script at the beginning to ensure that data is not duplicated

bash scripts/cleanup.sh 2>> log/errors.log

#Download all the files specified in data/filenames
#for url in $(<list_of_urls>) #TODO
#do
#    bash scripts/download.sh $url data
#done

echo -e "\n##### Downloading files... #####\n"

for url in $(cat data/urls)
do
	bash scripts/download.sh $url data
done

echo -e "\n\t\t###### Done. #####\n"

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
#bash scripts/download.sh <contaminants_url> res yes #TODO

echo -e "\n##### Uncompressing files... #####\n"

bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes

echo -e "\n\t\t##### Done. #####\n"

# Index the contaminants file
#bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

echo -e "\n##### Running STAR index... #####\n"

bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

echo -e "\n\t\t##### Done. #####\n"

# Merge the samples into a single file
#for sid in $(<list_of_sample_ids>) #TODO
#do
#    bash scripts/merge_fastqs.sh data out/merged $sid
#done

echo -e "\n##### Merging compressed files... #####\n"

for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::' | sort | uniq)
do
	echo -e "Merging $sid sample..."
	bash scripts/merge_fastqs.sh data out/merged $sid
done

echo -e "\n\t\t##### Done. #####\n"

# TODO: run cutadapt for all merged files
# cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
#     -o <trimmed_file> <input_file> > <log_file>

echo -e "\n##### Running cutadapt... #####\n"

mkdir -p out/trimmed
mkdir -p log/cutadapt

for sid in $(ls out/merged/*.fastq.gz | cut -d "." -f1 | sed 's:out/merged/::')
do
	 cutadapt \
                -m 18 \
                -a TGGAATTCTCGGGTGCCAAGG \
                --discard-untrimmed \
                -o out/trimmed/${sid}.trimmed.fastq.gz out/merged/${sid}.fastq.gz > log/cutadapt/${sid}.log
done

echo -e "\n\t\t##### Done. #####\n"

# TODO: run STAR for all trimmed files
#for fname in out/trimmed/*.fastq.gz
#do
    # you will need to obtain the sample ID from the filename
#    sid=#TODO
    # mkdir -p out/star/$sid
    # STAR --runThreadN 4 --genomeDir res/contaminants_idx \
    #    --outReadsUnmapped Fastx --readFilesIn <input_file> \
    #    --readFilesCommand gunzip -c --outFileNamePrefix <output_directory>
#done

echo -e "\n##### Running STAR... #####\n"

for fname in out/trimmed/*.fastq.gz
do

sid=$(echo $fname | sed 's:out/trimmed/::' | cut -d "." -f1)

mkdir -p out/star/$sid

	   STAR \
                --runThreadN 8 \
                --genomeDir res/contaminants_idx \
		--outReadsUnmapped Fastx \
                --readFilesIn ${fname} \
                --readFilesCommand gunzip -c \
                --outFileNamePrefix out/star/${sid}/
done

echo -e "\n\t\t##### Done. #####\n"

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in

echo -e "\n##### Creating a log file containing information from cutadapt and STAR logs... #####\n"

for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::' | sort | uniq)
do
	echo "Sample: " $sid >> log/pipeline.log
	echo "------------------" >> log/pipeline.log

	echo "Cutadapt: " >> log/pipeline.log
	echo $(cat log/cutadapt/$sid.log | grep -e "Reads with adapters") >> log/pipeline.log
	echo $(cat log/cutadapt/$sid.log | grep -e "Total basepairs") >> log/pipeline.log
	echo -e "\n" >> log/pipeline.log

	echo "STAR: " >> log/pipeline.log
	echo $(cat out/star/$sid/Log.final.out | grep -e "Uniquely mapped reads %") >> log/pipeline.log
	echo $(cat out/star/$sid/Log.final.out | grep -e "% of reads mapped to multiple loci") >> log/pipeline.log
	echo $(cat out/star/$sid/Log.final.out | grep -e "% of reads mapped to too many loci") >> log/pipeline.log
	
	echo -e "\n" >>log/pipeline.log
done

echo -e "\n\t\t##### Log file created. #####\n"

echo -e "\n##### Saving the environment... #####\n"

mkdir -p envs

conda env export > envs/decont.yaml

echo -e "\n\t\t##### Environment saved. #####\n"

echo -e "\n\n### Pipeline finished at $(date +'%H:%M:%S') ###\n\n"
