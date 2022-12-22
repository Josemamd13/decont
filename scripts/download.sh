###DONWLOAD SCRIPT BY JOSE MANUEL MUÑOZ###

# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
## Variables are defined:
fileurl=$1
outdir=$2
file=$(basename $1)
fileuncompress=$(basename $file .gz)

if [ -f "$1" ]
then

    if [ $(ls $2/*.fastq.gz 2>> /dev/null | wc -l ) -eq $(cat $1 | wc -l) ] ## Check if the file already exists.
    then

        echo "The files have already been downloaded."
	exit 0

    fi

		wget -c -P $2 -i $1

    echo -e "\n\t\t\t~~~ Checking md5sum... ~~~"

    for url in $(cat $1)
    do

        md5sum -c <(echo $(curl ${url}.md5 | grep s_sRNA. | cut -d " " -f1) $2/$(basename $url))

    done

    if [ "$?" -ne 0 ]
    then

        echo "md5sum checked failed" && exit 1

    fi

else
    if [ -e $2/$file ]
    then

        echo "The file have already been downloaded, uncompressed and filtered."
	exit 0

    fi

		wget -P $2 $1

    echo -e "\n\t\t\t~~~ Checking $file md5sum... ~~~"

	md5sum -c <(echo $(curl ${fileurl}.md5 | grep fasta.gz | cut -d " " -f1) $2/$file)

    if [ "$?" -ne 0 ]
    then

        echo "md5sum checked failed" && exit 1

    fi
fi

# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
if [ "$3" == "yes" ]
then

	echo -e "\nUncompressing..."
	gunzip -k $2/$file
	echo "Done."

fi

# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output
if [ "$4" == "filter" ]
then

	echo -e "\nFiltering..."
	seqkit grep -v -r -p "filter" -n $2/$file > $2/$fileuncompress
	echo "Done."

fi
