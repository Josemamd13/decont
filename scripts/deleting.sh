#Script created to be able to delete files created after testing

##Data
cd data
rm *.gz
rm *.fastq
cd ..

##Res
cd res
rm -r *
cd ..

##Out
cd out
rm -r *
cd ..

##Log
cd log
rm -r *
