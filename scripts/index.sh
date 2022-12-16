###INDEX SCRIPT CREATED BY JOSE MANUEL MUÑOZ ###

# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

# STAR --runThreadN 4 --runMode genomeGenerate --genomeDir <outdir> \
# --genomeFastaFiles <genomefile> --genomeSAindexNbases 9

if [ -e $2 ]
then
	echo "Index already created."
	exit 0
fi

mkdir -p res/contaminants_idx

	STAR \
		--runThreadN 8 \
		--runMode genomeGenerate \
		--genomeDir $2 \
		--genomeFastaFiles $1 \
		--genomeSAindexNbases 9
