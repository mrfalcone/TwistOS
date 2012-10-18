#=================================================
# TKernel makefile
#=================================================

include makedefs.mk

# name of executable
EXECNAME=TKernel.$(EXT)

# objects used for the kernel executable
OBJECTS = KernelDriver.o TwistKernel.o InterruptInterface.o BootScreen.o\
BootBMP320x200.o HardwareInterface.o


# standard C++ library objects and headers
CRTOBJECTS = $(CRTPATH)/cpp_krt.o 
STDOBJECTS= $(STDOBJPATH)/cstdfuncl_chstr.o


# main kernel executable
$(EXECNAME) : $(OBJECTS)
	$(LINKER) $(LINKERFLAGS) -T linkKernel.lds -o TKernel.$(EXT) $(CRTOBJECTS) $(OBJECTS) $(STDOBJECTS)


	
# kernel dependencies
KernelDriver.o : src/KernelDriver.cpp TwistKernel.o
	$(COMPILER) $(COMPILERFLAGS) $<


TwistKernel.o : src/TwistKernel.cpp src/TwistKernel.h InterruptInterface.o \
HardwareInterface.o BootScreen.o
	$(COMPILER) $(COMPILERFLAGS) $<


InterruptInterface.o : src/InterruptInterface.asm src/InterruptInterface.h
	$(ASSEMBLER) $(ASSEMBLERFLAGS) -o $(CURDIR)/$@ $<


BootScreen.o : src/BootScreen/BootScreen.cpp src/BootScreen/BootScreen.h BootBMP320x200.o
	$(COMPILER) $(COMPILERFLAGS) $<


BootBMP320x200.o : src/BootScreen/BootBMP320x200.asm src/BootScreen/BootBMP320x200.h
	$(ASSEMBLER) $(ASSEMBLERFLAGS) -o $(CURDIR)/$@ -i src/BootScreen/ $<


HardwareInterface.o : src/HardwareInterface.cpp src/HardwareInterface.h
	$(COMPILER) $(COMPILERFLAGS) $<


# make clean
clean:
	rm -f $(EXECNAME) $(OBJECTS)

