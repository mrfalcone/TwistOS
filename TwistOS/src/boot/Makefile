#=================================================
# boot.bin makefile
#=================================================

include makedefs.mk


# name of executable
EXECNAME=boot.bin


# assemble boot sector in flat-binary
$(EXECNAME) : boot_sector.asm
	$(ASSEMBLER) -f bin -o $(CURDIR)/$@ $<


# make clean
clean:
	rm -f $(EXECNAME)

