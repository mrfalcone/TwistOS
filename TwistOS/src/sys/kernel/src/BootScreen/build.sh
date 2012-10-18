#!/bin/bash 


cd ~/TwistOS/Kernel/Source/BootScreen/

# assemble asm files
for file in *.asm
do
	nasm -f elf32 ~/TwistOS/Kernel/Source/BootScreen/$file
done



# compile source code in elf32 format
/usr/cross/i586-elf/bin/g++.exe -idirafter ~/TwistOS/Kernel/Standard/include -fcheck-new -nostdinc -c  -x c++ ~/TwistOS/Kernel/Source/BootScreen/*.cpp

# -include ~/TwistOS/Kernel/Standard/include/*.h



#move object files up to main source dir
for file in *.o
do
	mv $file ../
done