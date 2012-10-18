#!/bin/bash 

osMain=~/TwistOS
osSource=$osMain/Source
osCompiled=$osMain/_OSRoot



# clean boot sector
cd $osSource/_boot
make clean -I $osMain
rm -f $osCompiled/boot.bin


# clean C/C++ standard library
cd $osSource/_cstd
make clean -I $osMain


# clean System directory
cd $osSource/System
	
for ebc in */
do
	len=${#ebc}-1
	execName=${ebc:0:len}.ebc
	
	cd $ebc
	make clean -I $osMain
	
	rm -f $osCompiled/System/$execName
	cd ..
done


