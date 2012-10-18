;========================================================================
; paging_32.asm -- procedures for setting up the system for paging
;					and virtual memory.
;
; * Modifies variable freeMemBlocks defined in 'kernel_loader.asm'
;
;
; PROCEDURES:
;-------------
;	InitPaging -- Sets up page directory table and prepares the system to use paging.
;	ClearPageDirectory -- Clears entire page directory.
;	MapPage -- Maps the specified physical address to the specified virtual address.
;	GetPageCount -- Determines the number of pages the specified bytes will use.
;
;
; Updated: 04/22/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------

PAGE_SIZE		EQU 4096		; size of a memory page
;------------------------------



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: InitPaging -- Sets up page directory table and prepares the system to use paging.
;							EAX must hold virtual kernel location. EBX must hold kernel size
;							in bytes. ECX must contain the physical location of the kernel
;							stack. EDX must contain the number of pages used by kernel stack.
;							ESI must contain the physical address of the address stack.
;							Returns: EAX returns identity mapped location of the page directory,
;							EBX returns the first free virtual address of kernel memory, ECX
;							returns virtual address of the kernel stack, EDX returns virtual
;							address of the address stack.
InitPaging:
	
	CLI							; disable interrupts during this procedure
	
	JMP .start					; jump to start of code
	
	.directoryLoc	DD 0		; this will hold location of the page directory table
	.kernelPhysLoc	DD 0		; this holds the physical kernel location
	.kernelVirLoc	DD 0		; this holds the virtual kernel location
	.kernelPages	DD 0		; number of pages used by the kernel
	.kStackLoc		DD 0		; this holds the physical kernel stack location
	.kStackVirLoc	DD 0		; virtual location of the kernel stack
	.kStackPages	DD 0		; number of pages for the kernel stack
	.aStackLoc		DD 0		; physical location of the address stack
	.aStackVirLoc	DD 0		; virtual location of the address stack
	.aStackPages	DD 0		; number of pages for the address stack

	.start:						; start of code
	
	MOV [.kernelVirLoc],EAX		; store virtual kernel location
	MOV [.kStackLoc],ECX		; store kernel stack location
	MOV [.kStackPages],EDX		; store kernel stack page count
	MOV [.aStackLoc],ESI		; store address stack location
	
	
	MOV EAX,EBX					; put kernel size into EAX to get the page count
	CALL GetPageCount			; get the number of pages used by the kernel
	MOV [.kernelPages],EAX		; store page count
	
	
	MOV EDX,ESP					; store current stack pointer in EDX
	MOV ESP,[.aStackLoc]		; set stack pointer to top of address stack
	
	
	.getPDTLoc:					; this loop will find the location of the pdt
		
		POP EAX					; get an address off the stack into EAX
		DEC DWORD [freeMemBlocks]	; decrement free block counter
		
		; now we will get the first address above 1mb to use for the pdt
		CMP EAX,100000h			; compare the address to 1mb position
		JAE .gotLoc				; if it's above or equal to 1mb, we got the location to use
		
		JMP .getPDTLoc			; otherwise loop back to check another address
		
		
	.gotLoc:					; jump here when the location is found
	
	
	MOV [.directoryLoc],EAX		; store the location

	
	MOV EAX,[.kernelVirLoc]		; get kernel's virtual location into EAX
	SHR EAX,22					; shift 22 bits to get the page table where the kernel begins
								; this is where supervisor pages begin
	MOV EBX,EAX					; move page table number into EBX to use in the loop
	
	
	MOV ECX,0					; clear ECX, it will store the current page entry
	MOV EDI,[.directoryLoc]		; set EDI to the beginning of the directory
	
	
	.setupDirectory:			; this loop sets up all 1024 entries in the page directory
		CMP ECX,1024			; see if we have setup 1024 entries yet
		JE .doneWithDirectory	; if we have, we're done
		
		
		POP EAX					; get the next address, this will be the page table's address
		DEC DWORD [freeMemBlocks]	; decrement free block counter
		
		OR EAX,11b				; set present bit and read/write bit
		
		CMP ECX,EBX				; see if this current entry is above the page table number of the kernel
		JAE .storeDirEntry		; if it's in supervisor area, go ahead and store
		
		OR EAX,111b				; otherwise make sure the user access bit is set
		
		
		.storeDirEntry:			; jump here to store the directory entry
		MOV [EDI],EAX			; store the entry
		
		INC ECX					; increment the page entry number
		ADD EDI,4				; add 4 to location within the directory, since each entry is 4 bytes
		
		JMP .setupDirectory		; loop back and setup the next entry
		
	.doneWithDirectory:			; jump here when done setting up the page directory
	

	
	
	MOV [.aStackLoc],ESP		; store the address of the top of the address stack
	MOV ESP,EDX					; restore the stack pointer
	
	
	
	MOV EDX,[.directoryLoc]		; get the directory table's location into EDX
	CALL ClearPageDirectory		; clear the page directory before mapping any pages

	
	
	
	MOV ECX,111b				; flags: present bit, read/write bit, user access bit
	MOV EDX,[.directoryLoc]		; get the directory table's location into EDX
	
	MOV EAX,0					; memory location to map
	
	.mapFirstMB:				; this loop identity maps the first mb of memory
		
		CMP EAX,100000h			; see if we have reached 1mb yet
		JAE .doneWithFirstMB	; if we have, we're done
		
		MOV EBX,EAX				; make sure both EBX and EAX are set to the same location
		
		CALL MapPage			; now map the page
		
		
		ADD EAX,PAGE_SIZE		; increase EAX by another page size
		JMP .mapFirstMB			; and loop back to keep mapping
		
		
	.doneWithFirstMB:			; jump here when done mapping the first mb
	
	
	
	; identity map the directory location
	MOV ECX,11b					; flags: present bit, read/write bit
	MOV EDX,[.directoryLoc]		; get the directory table's location into EDX
	MOV EAX,EDX					; set directory location as virtual address to map
	MOV EBX,EDX					; and also set it as physical location to map
	CALL MapPage				; and map it
	
	
	
	MOV ECX,1024				; we are going to map all 1024 page tables in the page directory
	MOV EDX,[.directoryLoc]		; get start of directory table into EDX

	.mapPageDirectory:			; this loop will identity map each page table in the page directory
		JECXZ .doneMappingDirectory	; when page table count gets to 0, we're done
		DEC ECX					; decrement page table counter
		
		MOV EAX,[EDX]			; get location of page table
		AND EAX,0FFFFF000h		; ignore all the flags
		
		
		PUSH EDX				; store position within page directory on the stack
		PUSH ECX				; store table counter on stack
		
		MOV EBX,EAX				; set physical location to same as table location
		
		MOV ECX,11b				; flags: present bit, read/write bit
		MOV EDX,[.directoryLoc]	; get the directory table's location into EDX
		
		CALL MapPage			; now map the page
		
		POP ECX					; restore table counter
		POP EDX					; restore the position within page directory
		
		ADD EDX,4				; increase position by 4 bytes for the next entry
		JMP .mapPageDirectory	; loop back and map the next entry
		
	.doneMappingDirectory:		; jump here when done mapping the directory
	
	
	
	; get the address where the kernel will begin
	MOV EDX,ESP					; store current stack pointer in EDX
	MOV ESP,[.aStackLoc]		; set stack pointer to top of address stack
	
	
	POP EAX						; get an address off the stack. this is where the kernel will begin
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	
	MOV [.kernelPhysLoc],EAX	; store physical location
	
	MOV EBX,EAX					; now set it as physical location for the MapPage procedure
	MOV EAX,[.kernelVirLoc]		; now set the virtual location
	MOV ECX,11b					; flags: present bit, read/write bit
	
	PUSH EDX					; push old stack pointer
	
	MOV EDX,[.directoryLoc]		; get the directory table's location into EDX
	
	CALL MapPage				; now map the page
	
	POP EDX						; restore old stack pointer
	
	
	; EAX will store the virtual location at which to map the next kernel page
	; start next reserved page for kernel one page after the kernel's start
	MOV EAX,[.kernelVirLoc]		; get kernel base virtual location
	ADD EAX,PAGE_SIZE			; add the page size
	
	MOV ECX,[.kernelPages]		; get number of pages needed by the kernel into ECX
	DEC ECX						; decrement it since we already mapped the first block
	
	
	.mapKernel:					; this loop reserves pages for the kernel and maps them
		JECXZ .doneWithKernel	; when we need 0 more pages, we're done
		DEC ECX					; decrement page counter
		
		POP EBX					; get another physical page for the kernel
		DEC DWORD [freeMemBlocks]	; decrement free block counter
		
		PUSH EAX				; store virtual location on stack
		PUSH ECX				; store page counter
		PUSH EDX				; store old stack pointer on stack
		
		
		MOV ECX,11b				; flags: present bit, read/write bit
		MOV EDX,[.directoryLoc]	; get the directory table's location into EDX
		
		CALL MapPage			; map the kernel page
		
		
		POP EDX					; restore old stack pointer
		POP ECX					; restore page counter
		POP EAX					; restore virtual location of current page
		
		ADD EAX,PAGE_SIZE		; increase virtual location by another page
		JMP .mapKernel			; loop back to map more kernel pages
		
	.doneWithKernel:			; jump here when done mapping kernel pages
	

	MOV [.aStackLoc],ESP		; store address stack pointer
	MOV ESP,EDX					; restore previous stack
	
	
	MOV EAX,[.kStackPages]		; get the number of kernel stack pages to use
	MOV EBX,[.kernelPages]		; get number of pages used by kernel
	
	ADD EAX,EBX					; add kernel pages to stack pages to get total page offset from start of kernel
	
	MOV EBX,PAGE_SIZE			; we are going to multiply by page size to get the correct byte offset for kstack
	MUL EBX						; perform the multiplication
	
	MOV EDX,[.kernelVirLoc]		; get the start of kernel in virtual memory
	
	ADD EDX,EAX					; add the byte offset. now EDX is the virtual address of the stack

	
	MOV [.kStackVirLoc],EDX		; store the location
	
	MOV EAX,EDX					; put virtual location into EAX
	MOV EBX,[.kStackLoc]		; get physical location in EBX
	MOV ECX,11b					; flags: present bit, read/write bit
	MOV EDX,[.directoryLoc]		; get the directory table's location into EDX
	
	CALL MapPage				; map the page
	
	
	
	MOV EAX,[.kStackVirLoc]		; use EAX for the virtual location being mapped
	SUB EAX,PAGE_SIZE			; start at the next page since we already mapped the first
								; using SUB since the stack grows downwards
	
	MOV EBX,[.kStackLoc]		; use EBX for the physical location being mapped
	SUB EBX,PAGE_SIZE			; start at the next page since we already mapped the first
	
	MOV ECX,[.kStackPages]		; get the number of pages we need to allocate for the kernel stack
	DEC ECX						; decrement it since we already mapped one page
	
	
	.mapKStack:					; this loop maps enough pages for the kernel stack
		JECXZ .doneWithKStack	; if we've mapped all the pages, we're done
		DEC ECX					; decrement page counter
		
		PUSHAD					; push registers
		
		; EAX and EBX are already properly set
		
		MOV ECX,11b				; flags: present bit, read/write bit
		MOV EDX,[.directoryLoc]	; get the directory table's location into EDX
		
		
		CALL MapPage			; map the kernel stack page	
		
		POPAD					; pop the registers
		
		SUB EAX,PAGE_SIZE		; point virtual location to the next page
		SUB EBX,PAGE_SIZE		; point physical location to the next page
		
		JMP .mapKStack			; loop back to map more pages	
		
	.doneWithKStack:			; jump here when done mapping the kernel stack
	
	
	
	;; map the pages used by the free address stack
	MOV EAX,[.aStackLoc]		; get physical location of the address stack into EAX
	AND EAX,111111111111b		; the first 12 bits specify the offset from the start of the page
	PUSH EAX					; push the offset onto stack so we can use it later
	
	SUB DWORD [.aStackLoc],EAX	; subtract offset to get the start of the page
	
	
	MOV EAX,[freeMemBlocks]		; get number of free memory blocks into EAX
	
	MOV EBX,4					; we will multiply by 4 since each address is 4 bytes
	MUL EBX						; now EAX is the total number of bytes in address stack
	
	CALL GetPageCount			; get the number of pages needed for address stack into EAX
	
	PUSH EAX					; push address stack page count onto stack
	
	
	MOV EDX,[.kStackVirLoc]		; get the top of kernel stack in virtual memory
	
	ADD EDX,(PAGE_SIZE*2)		; move up a couple pages to make room for the address stack
	
	MOV [.aStackVirLoc],EDX		; store the location
	
	
	MOV EAX,[.aStackVirLoc]		; put virtual location into EAX
	MOV EBX,[.aStackLoc]		; get physical location in EBX
	MOV ECX,11b					; flags: present bit, read/write bit
	MOV EDX,[.directoryLoc]		; get the directory table's location into EDX
	
	CALL MapPage				; map the page
	
	
	MOV EAX,[.aStackVirLoc]		; use EAX for the virtual location being mapped
	ADD EAX,PAGE_SIZE			; start at the next page since we already mapped the first
								; ADD because we're going upwards since stack is already populated
	
	MOV EBX,[.aStackLoc]		; use EBX for the physical location being mapped
	ADD EBX,PAGE_SIZE			; start at the next page since we already mapped the first
	
	POP ECX						; pop into ECX the number of pages we need to allocate for the address stack
	DEC ECX						; decrement it since we already mapped one page
	
	
	.mapAStack:					; this loop maps enough pages for the address stack
		JECXZ .doneWithAStack	; if we've mapped all the pages, we're done
		DEC ECX					; decrement page counter
		
		PUSHAD					; push registers
		
		; EAX and EBX are already properly set
		
		MOV ECX,11b				; flags: present bit, read/write bit
		MOV EDX,[.directoryLoc]	; get the directory table's location into EDX
		
		
		CALL MapPage			; map the kernel stack page	
		
		POPAD					; pop the registers
		
		ADD EAX,PAGE_SIZE		; point virtual location to the next page
		ADD EBX,PAGE_SIZE		; point physical location to the next page
		
		JMP .mapAStack			; loop back to map more pages	
		
	.doneWithAStack:			; jump here when done mapping the address stack
	POP EAX						; get the offset into stack page back off the stack
	
	; add it to the stack address
	ADD DWORD [.aStackVirLoc],EAX
	

	.return:
	STI							; re-enable interrupts
	
	MOV EAX,[.directoryLoc]		; return the directory location in EAX
	MOV ECX,[.kStackVirLoc]		; return kernel stack virtual address in ECX
	MOV EDX,[.aStackVirLoc]		; return address stack virtual address in EDX
	
	; return first free virtual address in EBX:
	MOV EBX,[.aStackVirLoc]		; the first free page is after this one
	ADD EBX,PAGE_SIZE			; add page size to point EBX to page after address stack
	AND EBX,0FFFFF000h			; mask out first 12 bits so address is page aligned
	
RET



; PROCEDURE: ClearPageDirectory -- Clears entire page directory. EDX must contain start
;									address of page directory table.
ClearPageDirectory:



	MOV ECX,1024				; we are going to clear all 1024 page tables in the page directory

	.clear:						; this loop will clear the page tables
	JECXZ .done					; when page table count gets to 0, we're done
	DEC ECX						; decrement page table count
	
	MOV EAX,[EDX]				; get location of page table from page directory
	AND EAX,0FFFFF000h			; ignore all the flags
	
	ADD EDX,4					; point EDX to next page table in page directory table
	PUSH EDX					; store location on stack

	MOV EDX,EAX					; put page table location into EDX
	
	
	
	MOV EAX,0					; clear EAX so we can set page table entries to 0
	PUSH ECX					; store ECX on stack
	
	MOV ECX,1024				; we have 1024 entries in each table that must be cleared
	
	.clearTable:				; this loop clears the current page table to 0
		JECXZ .doneWithTable	; when we have cleared all entries, we're done with the table
		DEC ECX					; decrement entry counter
		
		MOV [EDX],EAX			; set the dword at current entry in the table to 0
		
		ADD EDX,4				; increase EDX by 4 bytes
		JMP .clearTable			; loop back to keep clearing
		
	.doneWithTable:				; jump here when done with the page table
	
	POP ECX						; get page table count back off the stack
	
	POP EDX						; get location in page dir off stack
	
	JMP .clear					; loop back to keep clearing

	.done:
	
RET



; PROCEDURE: MapPage -- Maps the specified physical address to the specified virtual address.
;						EAX must contain a 4kb-aligned virtual address. EBX must contain
;						4kb-aligned physical address. ECX must contain the flags to be used
;						in the page table. ECX must contain base address of the page directory
;						table.
MapPage:

	PUSHAD						; store all registers

	OR EBX,ECX					; set bit flags
	PUSH EBX					; store physical address on stack
	
	
	MOV EBX,EAX					; put virtual address into EBX so we can get the page table entry number
	SHR EBX,12					; shift right to get page table entry number
	AND EBX,1111111111b			; we can only use 10 bits for entry number
	
	SHR EAX,22					; shift virtual address right to get page directory entry number
	
	PUSH EDX					; push page directory location onto stack since MUL instruction clears it
	
	MOV ECX,4					; we multiply the directory entry number in EAX by 4 since each entry is 4 bytes
	MUL ECX						; perform the multiplication
	
	POP EDX						; get page directory location back off the stack
	ADD EDX,EAX					; add to start of page directory so EDX points to the page table we need
	
	MOV EAX,[EDX]				; get the location of the page table that we need
	AND EAX,0FFFFF000h			; ignore all the flags
	
	
	MOV EDX,EAX					; put location of the page table into EDX

	PUSH EDX					; push page table location onto stack since MUL instruction clears it
	
	
	MOV EAX,EBX					; put page table entry number into EAX
	
	MOV ECX,4					; we multiply the table entry number in EAX by 4 since each entry is 4 bytes
	MUL ECX						; perform the multiplication
	
	POP EDX						; get page table location back off the stack
	ADD EDX,EAX					; add to start of page table so EDX points to the page table entry we need
	
	
	POP EBX						; get the physical address we need off the stack
	MOV [EDX],EBX				; store it at the location in the page table

	
	POPAD						; restore all registers back to normal
RET



; PROCEDURE: GetPageCount -- Determines the number of pages the specified bytes will use.
;								EAX must contain number of bytes when called. EAX returns
;								number of pages to use.
GetPageCount:

	MOV EBX,PAGE_SIZE			; we're going to divide by page size to get the number of pages needed
	MOV EDX,0					; clear EDX for remainder
	DIV EBX						; perform the division
	
	CMP EDX,0					; see if there is a remainder
	JE .return					; if not, just return
	
	INC EAX						; otherwise add one more to the number of pages to be sure there's enough space
	
	.return:
RET

