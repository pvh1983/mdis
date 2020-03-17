#!/bin/bash

INPUTFILE="parentpmp.txt"
MFILE="expdsg_run.m"
OUTFILE="MinEED.dat"


#Count the size of the population
npop=`wc -l $INPUTFILE | awk '{print $1}'`
nproc=`wc -l $PBS_NODEFILE | awk '{print $1}'`

#Build a host list
count=0
export workdir=`pwd`
HOSTLIST=
for host in `cat $PBS_NODEFILE`
  do
    HOSTLIST[$count]=$host
    count=$(( $count + 1 ))
done

count=1
pcount=0
while read line
  do
	  mkdir run_$count
	  cd run_$count
	  mkdir GP1
	  cd GP1
		ln -s $workdir/GP1/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..
	  mkdir GP2
	  cd GP2
		ln -s $workdir/GP2/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  
	  mkdir GP3
	  cd GP3
		ln -s $workdir/GP3/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  	  
	  mkdir IK1
	  cd IK1
		ln -s $workdir/IK1/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  	  
	  
	  mkdir IK2
	  cd IK2
		ln -s $workdir/IK2/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  	  	  
	  mkdir IK3
	  cd IK3
		ln -s $workdir/IK3/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  	  	  	  
	  mkdir IZ1
	  cd IZ1
		ln -s $workdir/IZ1/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  	  	  	  
	  mkdir IZ2
	  cd IZ2
		ln -s $workdir/IZ2/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  	  	  	  
	  mkdir IZ3
	  cd IZ3
		ln -s $workdir/IZ3/* .
		rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
	  cd ..	  	  	  	  
	  mkdir TrueGP2
	  cd TrueGP2
		ln -s $workdir/TrueGP2/* .
		rm -f mf54._os mf54.wel *.out fort.*
	  cd ..
	  ln -s $workdir/*.* .  
#	  ln -s $workdir/gapmp
	  ln -s $workdir/gaobs
	  
      echo $line > param.txt
	remotehost=${HOSTLIST[$pcount]}
	ssh -n $remotehost "cd $workdir/run_$count; export PATH=$PATH:$workdir/run_$count; octave -qH --no-window-system $MFILE > /dev/null" &
    if [ $(( $count%$nproc )) -eq 0 ]
        then
	  		pcount=-1
#	  		echo "Processing job $count..."
			  wait
        fi
        cd ..
	let count+=1
	let pcount+=1	
done < $INPUTFILE

