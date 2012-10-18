#=================================================
# TKLD makefile
#=================================================

include makedefs.mk


# name of executable
EXECNAME=TKLD.$(EXT)


# assemble kernel loader in flat-binary
$(EXECNAME) : kernel_loader.asm
	$(ASSEMBLER) -f bin -o $(CURDIR)/$@ $<


# make clean
clean:
	rm -f $(EXECNAME) $(OBJECTS)

