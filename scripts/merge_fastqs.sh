###MERGE SCRIPT BY JOSE MANUEL MUÑOZ###

# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).
##Define variables:
inputdir=$1
outputdir=$2
sid=$3

if [ -e $2/$3.fastq.gz ] ##Check if the file already exists.
then
	echo "The merger has already been made."
	exit 0
fi

mkdir -p out/merged

	cat $1/$3* > $2/$3.fastq.gz

