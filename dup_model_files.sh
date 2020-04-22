#!/bin/bash

export workdir="/work/ftsai/h1S4_pmp2000_max_min/"

mkdir GP1
cd GP1
ln -s $workdir/GP1/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)

mkdir GP2
cd GP2
ln -s $workdir/GP2/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)

mkdir GP3
cd GP3
ln -s $workdir/GP3/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)

mkdir IK1
cd IK1
ln -s $workdir/IK1/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..	  	  
echo $(pwd)


mkdir IK2
cd IK2
ln -s $workdir/IK2/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)

mkdir IK3
cd IK3
ln -s $workdir/IK3/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)

mkdir IZ1
cd IZ1
ln -s $workdir/IZ1/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)

mkdir IZ2
cd IZ2
ln -s $workdir/IZ2/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)

mkdir IZ3
cd IZ3
ln -s $workdir/IZ3/* .
rm -f mf54.lpf mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)	  	  	  


mkdir TrueGP2
cd TrueGP2
ln -s $workdir/TrueGP2/* .
rm -f mf54._os mf54.wel *.out fort.*
cd ..
echo $(pwd)


