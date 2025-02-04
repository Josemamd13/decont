###RNA DECONTAMINATION PIPELINE BY José Manuel Muñoz###

echo -e "\n\n~~~ Pipeline started at $(date +'%H:%M:%S')... ~~~\n\n"

#Run cleanup script at the beginning to ensure that data is not duplicated.
#bash scripts/cleanup.sh 2>> log/errors.log

#Download all the files specified in data/filenames
#for url in $(<list_of_urls>) #TODO
#do
#    bash scripts/download.sh $url data
#done
echo -e "\n~~~~~ Downloading files... ~~~~~\n"

bash scripts/download.sh data/urls data

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
#bash scripts/download.sh <contaminants_url> res yes #TODO
echo -e "\n~~~~~ Downloading, uncompressing and filtering the contaminants fasta files... ~~~~~\n"

bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes filter

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

# Index the contaminants file
#bash scripts/index.sh res/contaminants.fasta res/contaminants_idx
echo -e "\n~~~~~ Running STAR index... ~~~~~\n"

bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

# Merge the samples into a single file
#for sid in $(<list_of_sample_ids>) #TODO
#do
#    bash scripts/merge_fastqs.sh data out/merged $sid
#done
echo -e "\n~~~~~ Merging compressed files... ~~~~~"

for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::' | sort | uniq)
do
	echo -e "\nMerging $sid sample... \n"
	bash scripts/merge_fastqs.sh data out/merged $sid
done

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

# TODO: run cutadapt for all merged files
# cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
#     -o <trimmed_file> <input_file> > <log_file>
echo -e "\n~~~~~ Running cutadapt... ~~~~~\n"

	mkdir -p out/trimmed
	mkdir -p log/cutadapt

for sid in $(ls out/merged/*.fastq.gz | cut -d "." -f1 | sed 's:out/merged/::')
do
	if [ -e out/trimmed/${sid}.trimmed.fastq.gz ]
	then
        	echo "Sample $sid has already been trimmed."
        	continue
	fi

	 cutadapt \
                -m 18 \
                -a TGGAATTCTCGGGTGCCAAGG \
                --discard-untrimmed \
                -o out/trimmed/${sid}.trimmed.fastq.gz out/merged/${sid}.fastq.gz > log/cutadapt/${sid}.log
done

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

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
echo -e "\n~~~~~ Running STAR... ~~~~~\n"

for fname in out/trimmed/*.fastq.gz
do

	sid=$(echo $fname | sed 's:out/trimmed/::' | cut -d "." -f1)

	if [ -e out/star/$sid/ ]
	then
        	echo "STAR alignment for sample $sid has already been done."
        	continue
	fi

	mkdir -p out/star/$sid

	   STAR \
                --runThreadN 8 \
                --genomeDir res/contaminants_idx \
		--outReadsUnmapped Fastx \
                --readFilesIn $fname \
                --readFilesCommand gunzip -c \
                --outFileNamePrefix out/star/$sid/
done

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
echo -e "\n~~~~~ Creating a log file containing information from cutadapt and STAR logs... ~~~~~\n"

if [ -e log/pipeline.log ]
then
	echo "Pipeline has already been done."
fi

for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::' | sort | uniq)
do
	echo "Sample: " $sid >> log/pipeline.log
	echo "------------------" >> log/pipeline.log

	echo "Cutadapt: " >> log/pipeline.log
	echo $(cat log/cutadapt/$sid.log | egrep "Reads with adapters") >> log/pipeline.log
	echo $(cat log/cutadapt/$sid.log | egrep "Total basepairs") >> log/pipeline.log
	echo -e "\n" >> log/pipeline.log

	echo "STAR: " >> log/pipeline.log
	echo $(cat out/star/$sid/Log.final.out | egrep "Uniquely mapped reads %") >> log/pipeline.log
	echo $(cat out/star/$sid/Log.final.out | egrep "% of reads mapped to multiple loci") >> log/pipeline.log
	echo $(cat out/star/$sid/Log.final.out | egrep "% of reads mapped to too many loci") >> log/pipeline.log

	echo -e "\n" >>log/pipeline.log
done

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

echo -e "\n~~~~~ Saving the environment... ~~~~~\n"
if [ -e envs/decont.yaml ]
then
	echo "The environment has already been saved."
fi

	mkdir -p envs

	conda env export > envs/decont.yaml

echo -e "\n\t\t\t~~~~~ Done. ~~~~~\n"

echo -e "\n\n~~~ Pipeline finished at $(date +'%H:%M:%S') ~~~\n\n"
