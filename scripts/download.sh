###DONWLOAD SCRIPT BY JOSE MANUEL MUÑOZ###

# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
##Define variables:
file=$(basename $1)

if [ -e $2/$file ] ##Check if the file already exists.
then
	echo "File $file has already been downloaded."
	exit 0
fi

	wget -P $2 $1

# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"

if [ "$3" = "yes" ]
then
	gunzip -k $2/$file
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
##Define variables:
file_uncompress=$(basename $file .gz)

if [ "$4" = "filter" ]
then
	seqkit grep -v -r -p "filter" -n $2/$file > $2/$file_uncompress
fi
