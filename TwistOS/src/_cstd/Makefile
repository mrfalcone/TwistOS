#=================================================
# C/C++ standard library makefile
#=================================================

include makedefs.mk


CRTOBJECTS=$(CRTPATH)/cpp_krt.o
STDOBJECTS=$(STDOBJPATH)/cstdfuncl_chstr.o




$(CRTPATH)/cpp_krt.o : src/cpp_krt.asm $(STDOBJECTS)
	$(ASSEMBLER) $(ASSEMBLERFLAGS) -o $@ $<

	
$(STDOBJPATH)/cstdfuncl_chstr.o : src/cstdfuncl_chstr.asm
	$(ASSEMBLER) $(ASSEMBLERFLAGS) -i src/ -o $@ $<
	

	
clean:
	rm -f $(CRTOBJECTS) $(STDOBJECTS)

