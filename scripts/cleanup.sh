###CLEANUP SCRIPT BY José Manuel Muñoz###

#If we do not pass any argument to the script, what it will do is to delete all 
#the files that it finds with a depth of 1, except for those that we protect (!)
if [ "$#" -eq 0 ]
then
	find data ~/decont -maxdepth 1 -type f ! ( -name urls -o -name .gitkeep -o -name .gitignore -o -name README.md \) -delete
	find log envs out res -mindepth 1 ! -name .gitkeep -delete
	
	echo -e "\t\t##### Everything has been deleted. #####"
else
	args=$@
fi

#In case we pass any argument ("data", "log", "out", "res" or "envs") only files
#belonging to that directory with a depth of 1 will be deleted.
for arg in $args
do
	case $arg in
		"data")
			find data -maxdepth 1 -type f ! \( -name urls -o -name .gitkeep \) -delete
			echo "$arg directory is empty"
			;;
		"log")
			find log -mindepth 1 ! -name .gitkeep -delete
			echo "$arg directory is empty"
			;;
		"out")
                        find out -mindepth 1 ! -name .gitkeep -delete
                        echo "$arg directory is empty"
			;;
		"res")
			find res -mindepth 1 ! -name .gitkeep -delete
                        echo "$arg directory is empty"
			;;
		"envs")
			find envs -mindepth 1 ! -name .gitkeep -delete
			echo "$arg directory is empty"
			;;
		*) echo "$arg directory does not exist..."
		esac
done
