if [ -z ${century+x} ]; then century=$1; fi 
if [ -z ${decade+x} ]; then decade=$2; fi 
if [ -z ${year+x} ]; then year=$3; fi 

#century=19
#decade=99
#year=1999

cd EastCoast/release_locations/
numfiles=(*)
numfiles=${#numfiles[@]}
cd
#rm -rfv go.sh.*
#rm -rfv run.sh.*
#rm -rfv run_sub.sh.*
#rm -rfv /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year
#rm -rfv /sb/project/uxb-461-aa/Cuke-MPA/output/E$year

again=false

for t in {152..212}
#for t in {152..153}
do
	#for i in {80..82}
	for i in `eval echo {1..$numfiles}`
	do
		cd /sb/project/uxb-461-aa/Cuke-MPA/output/E$year/$[t]/$[i]/
		n=(*)
		n=${#n[@]}
		cd
		if [ $n != "121" ] ; then
			again=true
			rm -rf /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]
			rm -rf /sb/project/uxb-461-aa/Cuke-MPA/output/E$year/$[t]/$[i]
			mkdir -p /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]
			mkdir -p /sb/project/uxb-461-aa/Cuke-MPA/output/E$year/$[t]/$[i]

			cp EastCoast/* /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/

			rm -rf /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/release_locations.txt
			cp EastCoast/release_locations/rl_$i.txt /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/release_locations.txt

			sed -i -e "s/timetobereplaced/$t/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/run_sub.sh
			sed -i -e "s/celltobereplaced/$i/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/run_sub.sh
			sed -i -e "s/grid/E$year/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/run_sub.sh
			
			mv /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/run_sub.sh /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/run_sub_$year.sh

			
			#sed -i -e "s/filenum = 1/filenum = $t/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data
			module load R/3.1.2
			Rscript /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/lag.R $t $i $year

			
			sed -i -e "s/outputtobereplaced/E$year/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data
			sed -i -e "s/timetobereplaced/$t/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data
			sed -i -e "s/celltobereplaced/$i/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data
			nparts=$(cat /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/release_locations.txt | wc -l)
			sed -i -e "s/99999999/$nparts/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data
			sed -i -e "s/yeartobereplaced/$year/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data
			sed -i -e "s/decadetobereplaced/$decade/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data	
			#if [ $decade -ne 98 ]
			#then
				#sed -i -e "s/_gb_his_/_his_/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i]/LTRANS.data
			#fi
			
			cd /sb/project/uxb-461-aa/Cuke-MPA/runs/E$year/$[t]/$[i] 
			qsub -A uxb-461-aa run_sub_$year.sh
			cd
			echo "day $t bin $i is missing files"
		fi
	done
done 

if $again ; then
	dt=$(date --date="+1 day" '+%m%d%H%M')
    qsub -a $dt -A uxb-461-aa go_east.sh -v century=$century -v decade=$decade -v year=$year
fi