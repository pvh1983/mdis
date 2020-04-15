#!/bin/bash

INPUTFILE="parentpmp.txt"
MFILE="expdsg_run.m"
OUTFILE="MinEED.dat"


#Count the size of the population
#npop=`wc -l $INPUTFILE | awk '{print $1}'`
#nproc=`wc -l $PBS_NODEFILE | awk '{print $1}'`


#Build a host list
#count=0
export workdir=`pwd`
#HOSTLIST=
#for host in `cat $PBS_NODEFILE`
#  do
#    HOSTLIST[$count]=$host
#    count=$(( $count + 1 ))
#done

count=161
pcount=0
while read line
  do
	if [ ! -d run_$count ]
	then	  
	  mkdir run_$count
	  cd run_$count	  
	fi

	cd $workdir/run_$count	  
    echo $line > param.txt
	rm -f out*.mat func_runtime.txt result*.dat
	#remotehost=${HOSTLIST[$pcount]}
	#ssh -n $remotehost "cd $workdir/run_$count; export PATH=$PATH:$workdir/run_$count; octave -qH --no-window-system $MFILE > /dev/null" &
    #if [ $(( $count%$nproc )) -eq 0 ]
    #    then
	#  		pcount=-1
	#		#count=0  # commentout if limit number of run folders to nproc
#	#  		echo "Processing job $count..."
	#		  wait
    #    fi
        cd ..
	let count+=1
	let pcount+=1	
done < $INPUTFILE

