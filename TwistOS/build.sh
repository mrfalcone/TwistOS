#!/bin/bash 

osMain=~/TwistOS
osSource=$osMain/src
osCompiled=$osMain/bin



# build boot sector
cd $osSource/boot
make -I $osMain
cp -u boot.bin $osCompiled/




# build C/C++ standard library
cd $osSource/_cstd
make -I $osMain




# build System directory
cd $osSource/sys
	
for ebc in */
do
	len=${#ebc}-1
	execName=${ebc:0:len}.ebc
	
	cd $ebc
	make -I $osMain
	
	cp -u $execName $osCompiled/sys/
	cd ..
done


