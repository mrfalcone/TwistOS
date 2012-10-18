;========================================================================
; kernel_loader.asm -- program that loads the kernel into memory and boots
;						it. This is the second stage in booting the OS and
;						is loaded by the boot sector.
;
;
; -- Assembled with NASM 2.06rc2 --
; Updated: 04/22/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------

KL_POS			EQU 0000D000h	; position where this code is loaded in memory by the boot sector


MINMEM			EQU 30000		; minimum amount of memory required in KB

MAP_POS			EQU 7000		; position at which to read memory map

KSTACK_BLOCKS	EQU 256			; number of 4kb pages to use for kernel stack. 256 pages is 1mb stack

VIR_KERNEL_POS	EQU 0C0000000h	; virtual location at which to map the kernel


EXEC_PAUSE		EQU 3			; number of seconds to pause before jumping to the kernel
MENU_KEY_CODE	EQU 0C2h		; scan code of the key to press to enter the menu (F8)

;------------------------------



[BITS 16]
[ORG KL_POS]					; this code is loaded by the boot loader at this position


; include the EBC header information for the kernel loader:
%include "include/TKLD_header.asm"


JMP Stage2						; start stage 2


;------------------------------
; PROGRAM DATA / STRINGS
;------------------------------

;; file names

; name of the kernel file that will be loaded from the disk:
kernelName		DB "TKernel.ebc",0
; name of the kernel driver that reads the disk from which OS is booted:
dDriverName		DB "ATA.tkd",0
; name of the kernel driver that reads the filesystem to which the disk is formatted:
fsDriverName	DB "ISO9660.tkd",0


;; uninitialized data
memSize				DD 0		; will store the memory size in kb
memBlocks			DD 0		; will store the number of total possible memory blocks

freeMemBlocks 		DD 0		; will store number of free memory blocks after memory is setup


addrStackPointer	DD 0		; this will store the physical address of the top of the stack of free addresses
aStackVirPointer	DD 0		; this will store the virtual address of the free address stack

kStackPointer		DD 0		; this will store the physical address of the top of the kernel stack
kStackVirPointer	DD 0		; this will store the virtual address of the kernel stack


kernelSize			DD 0		; this will store the size the kernel requires in bytes
kernelBlock			DD 0		; this will store the block number where the kernel starts on disk

dDriverSize			DD 0		; this will store the size the disk driver requires in bytes
dDriverBlock		DD 0		; this will store the block number where the disk driver starts on disk

fsDriverSize		DD 0		; this will store the size the filesystem driver requires in bytes
fsDriverBlock		DD 0		; this will store the block number where the filesystem driver starts on disk


pageDirectoryLoc	DD 0		; this will store the location of the page directory in memory


tssLoc				DD 0		; location of TSS page
tssPermMap			DD 0		; location of the TSS's port I/O permission bitmap

freeVirtualAddr		DD 0		; first free virtual memory address


;; strings
newline		DB 10,0

strPrep		DB " Preparing Kernel Environment",10
			DB "ออออออออออออออออออออออออออออออ",10,10,0

strMem1		DB " ฏ Available system memory: ",0
strMem2		DB " KB.",10,0

strDiskDrv1	DB " ฏ Disk driver: ",0
strDiskDrv2 DB " - ",0
strDiskDrv3	DB " bytes.",10,0

strFSDrv1	DB " ฏ Filesystem driver: ",0
strFSDrv2 	DB " - ",0
strFSDrv3	DB " bytes.",10,0


strPaging	DB " ฏ Paging enabled.",10,0


strDiskRead	DB " ฏ Reading disk. This may take a moment...",10,0


strBootMenu	DB 10,10," Press F8 to access boot menu...",10,0


strExec1	DB 10," ฏ Executing kernel.",0
strExec2	DB ".",0


;; error strings
errLowMem		DB "System requires at least 32 MB of memory!",0

errA20			DB "Error enabling A20 gate!",0

errMemSize		DB "Error reading memory size!",0
errMemMap		DB "Error accessing memory map!",0

;------------------------------
; 16 BIT INCLUDES
;------------------------------

;; these files contain 16-bit code necessary for the boot process
;  before we enter protected mode

; this file contains procedures dealing with display and prints strings
%include "include/screen_16.asm"
; this file handles enabling the A20 gate:
%include "include/a20_16.asm"
; this file sets up and installs the GDT:
%include "include/gdt_16.asm"
; this file tests memory and gets memory map:
%include "include/memory_16.asm"
; this file handles checking for errors
%include "include/error_16.asm"



;------------------------------
; BEGIN STAGE 2 OF BOOT PROCESS
;------------------------------
Stage2:	
	
	CALL Clear16				; clear the screen
	

;------------------------------
; DISABLE KEYBOARD
;------------------------------

	; disable the keyboard until later
	
	MOV AL,0ADh						; command to disable the keyboard
	OUT 64h,AL						; send it to the keyboard command controller
	
	
;------------------------------
; ENABLE A20 GATE
;------------------------------

	CLI							; clear interrupts
	;; defined in 'a20_16.asm':
	CALL A20Enable				; enable the a20 gate
	
	STI							; re-enable interrupts
	
	MOV SI,errA20				; get a20 error string
	CALL CheckError				; check to see if there was an error
	
	
	
;------------------------------
; GET MEMORY INFO
;------------------------------

	;; defined in 'memory_16.asm':
	CALL GetMemorySize			; get the size of memory
	
	MOV SI,errMemSize			; get error string
	CALL CheckError				; check to see if there was an error
	
	
	;; now EDX contains the total KB of memory in the system
	
	MOV [memSize],EDX			; store in memSize
	
	CMP EDX,MINMEM				; test to see if we have enough memory
	JA EnoughMem				; if we do, move on
	
	
	; if not, give an error
	MOV SI,errLowMem			; not enough memory string
	CALL Print16				; print string
	JMP Hang					; hang the system
	
	
	EnoughMem:					; jump here if we have enough memory
	
	
;------------------------------
; GET MEMORY MAP
;------------------------------
	
	;; defined in 'memory_16.asm':	
	MOV DI,MAP_POS				; set the location of the memory map
	CALL GetMemoryMap			; call the procedure
	
	MOV SI,errMemMap			; get error string
	CALL CheckError				; check to see if there was an error
	
	
;------------------------------
; HIDE TEXT CURSOR
;------------------------------

	; this will move the text cursor off the screen so that it will not be visible
	MOV AH,02h					; set cursor bios function
	MOV BH,0					; page 0
	MOV DH,1Eh					; set row to 30
	MOV DL,0					; set column to 0
	INT 10h						; run the video interrupt
	
	
	
;------------------------------
; LOAD GDT FOR KERNEL LOADER
;------------------------------
	;; defined in 'gdt_16.asm':
	CALL LoadGDT				; load the global descriptor table
	
	
	
;------------------------------
; SWITCH CPU TO P-MODE
;------------------------------

	CLI							; make sure interrupts are disabled

	;; enter protected mode
	 MOV EAX,CR0				; copy contents of CR0 into EAX	
	 OR EAX,1					; set bit 0 to 1		
	 MOV CR0,EAX				; copy data back to CR0 with bit 0 set
	
	
	MOV AX,18h					; tss selector
	LTR AX						; load task register

	
	JMP 08h:Start32				; flush instruction queue and set CS

	
	
	
	
	
	
	
;==============================================================================
;------------------------------
; ENTER 32-BIT PROTECTED MODE
;------------------------------
	
[BITS 32]						; from this point on, we use 32 bit code


Start32:

	MOV EAX,10h					; set EAX to data segment identifier
	MOV DS,EAX					; set DS to start of data
	MOV ES,EAX					; set ES to start of data
	MOV FS,EAX					; set FS to start of data
	MOV GS,EAX					; set GS to start of data
	MOV SS,EAX					; set SS to start of data
	
	MOV ESP,0F00000h			; set a large temp stack
	MOV EBP,0

	JMP Prep					; begin prepping for kernel
	

;; this file contains procedures for printing on the screen
%include "include/screen_32.asm"
;; this file contains code for setting up the kernel loader's IDT
%include "include/idt_32.asm"
;; this file contains code for setting up the kernel loader's PIC
%include "include/picsetup_32.asm"
;; this file contains code for setting up the PIT
%include "include/pit_32.asm"
;; this file contains code for handling the keyboard
%include "include/keyboard_32.asm"
;; this file contains code for timing
%include "include/timer_32.asm"
;; this file contains code for setting up paging
%include "include/paging_32.asm"
;; this file contains code for the boot menu
%include "include/menu_32.asm"

;; this file contains code for reading files and file info from the boot CD
%include "include/cdfilereader_32.asm"



;------------------------------
; BEGIN PREPARING
;------------------------------
	
Prep:
	CALL ClearScreen			; clear the screen
	
	
	MOV ESI,strPrep				; get the prep string
	CALL PrintString			; and print it
	
	
	;; begin preparing kernel environment

	
	
;------------------------------
; SETUP IDT FOR KERNEL LOADER
;------------------------------	

	;; defined in 'idtsetup_32.asm'
	CALL SetupIDT


;------------------------------
; SETUP PIC FOR KERNEL LOADER
;------------------------------	
	
	;; defined in 'picsetup_32.asm'
	CALL PICInit

	
;------------------------------
; SETUP THE PIT
;------------------------------	
	
	;; defined in 'pit_32.asm'
	CALL PITInit
	
	
	
;------------------------------
; ENABLE INTERRUPTS
;------------------------------	

	;; finally re-enable the interrupts
	STI
	
	

;------------------------------
; INITIALIZE DISK
;------------------------------	

	MOV ESI,strDiskRead			; get disk read string
	CALL PrintString			; print it
	

	CALL MountDisk				; mount the disk to prepare it for use by the kernel loader
	

	
;------------------------------
; READ FILE INFO
;------------------------------

	;; we are going to read the size and block number of each needed file.
	;  after reading, we use the size to allocate memory. later we use this data
	;  to read the files directly from the disk
	
	

	;; read kernel file information from the disk:
	;
	MOV ESI,kernelName			; name of the file to read
	MOV EAX,0					; 0 means that the file is in the system directory
	CALL ReadFileInfoFromDisk	; read the file info
	MOV [kernelBlock],EAX		; EAX returns the block number of the file
	MOV [kernelSize],EBX		; EBX returns the block number of the file
	
	
	
	;; read disk driver file information from the disk:
	;
	MOV ESI,dDriverName			; name of the file to read
	MOV EAX,1					; 1 means that the file is in the driver directory
	CALL ReadFileInfoFromDisk	; read the file info
	MOV [dDriverBlock],EAX		; EAX returns the block number of the file
	MOV [dDriverSize],EBX		; EBX returns the block number of the file
	
	
	
	;; read filesystem driver file information from the disk:
	;
	MOV ESI,fsDriverName		; name of the file to read
	MOV EAX,1					; 1 means that the file is in the driver directory
	CALL ReadFileInfoFromDisk	; read the file info
	MOV [fsDriverBlock],EAX		; EAX returns the block number of the file
	MOV [fsDriverSize],EBX		; EBX returns the block number of the file
	
	
	

;------------------------------
; READ MEMORY MAP
;------------------------------

	;; MemMapEntry structure is defined in 'memory_16.asm'
	
	
	MOV EAX,[memSize]			; get the memory size in kb
	MOV EBX,1024				; multiply by 1024 to convert to size in bytes
	MUL EBX						; perform the multiplication
	MOV EDX,EAX					; store the memory size in bytes in the EDX register
	
	MOV ECX,0					; this register will store the address of the current block we are working with
	
	
	MOV ESI,MAP_POS				; grab the position of the start of the memory map
	
	
	;; now registers are like so:
	;  EDX = max memory size in bytes
	;  ESI = start of the memory map in memory
	;  ECX = address of current block


	
	;; begin parsing memmap entries
	ParseEntry:
		
		; get the type of region:
		MOV EAX,[ESI+MemMapEntry.type]
		
		CMP EAX,1				; see if type is 1, 1=available memory
		
		JNE .nextEntry			; if it's unavailable, go to the next entry
		
		
		; if the region is available, get block addresses and push them onto the stack
		
		.getBlock:				; jump here to keep trying to get a block inside available region
		 
		 
		 ; get the base of current region:
		 MOV EAX,[ESI+MemMapEntry.base]
		 
		 
		 CMP EAX,ECX			; compare the base of the region to the address of the current block
		 JA .nextBlock			; if current block address is less than base of the memmap entry, go to next block
		 
		 
		 ; if we're still within the region, store the address
		 
		 PUSH ECX				; push the address of the current block onto the stack
		 
		 ; increment counter of free memory blocks:
		 INC DWORD [freeMemBlocks]
		
		
		
		.nextBlock:				; jump here to go to the next block of memory
		 
		 ADD ECX,4096			; increase ECX by size of another block
		 
		 
		 ; get the base of region:
		 MOV EAX,[ESI+MemMapEntry.base]
		 
		 ; get length of memory region:
		 MOV EBX,[ESI+MemMapEntry.length]
		 
		 
		 ADD EAX,EBX			; get the end of the memory region
		 
		 CMP EAX,ECX			; compare the end of the memory region to address of the end of the next block
		 JB .nextEntry			; go to the next entry if ECX goes past end of available region
		 
		 JMP .getBlock			; go to the next block
		
		
		
		.nextEntry:				; go to the next entry in the memory map
		 
		 ; get the base of region:
		 MOV EAX,[ESI+MemMapEntry.base]
		 
		 ; get length of memory region:
		 MOV EBX,[ESI+MemMapEntry.length]
		 
		 ADD EAX,EBX			; get the end of the memory region
		 
		 
		 CMP EAX,EDX			; compare end of mem region to total memory
		 
		 JAE .done				; if we reached end of memory, we're done
		 
		 
		 ; if there's still more memory to read, keep reading the map
		 
		 ;; MAP_SIZE defined in 'memory_16.asm'
		 ADD ESI,MAP_SIZE		; increase our position in the memory map by the size of a map entry
		 
		 
		 JMP ParseEntry			; parse the next entry
		
		
	.done:						; jump here when finished reading the memory map

	MOV EAX,[freeMemBlocks]		; get the total number of free memory blocks
	MOV [memBlocks],EAX			; and store it in the memBlocks variable

;------------------------------
; PRINT AVAILABLE MEMORY
;------------------------------	
	
	MOV ESI,strMem1				; put mem string into ESI
	CALL PrintString			; print it
	
	
	MOV EAX,[memBlocks]			; put number of total available memory blocks into EAX
	MOV EBX,4					; number of KB in each block
	MUL EBX						; multiply by number of KB in each block to get total KB
	
	CALL PrintNumber			; now print the total available system memory
	
	MOV ESI,strMem2				; put mem string into ESI
	CALL PrintString			; and print it
	
	
	
;------------------------------
; SETUP ADDRESS STACK
;------------------------------
	
	;; now we will pop addresses we just stored and store them in a stack starting
	;  at addrStackPointer from lowest to highest
	
	POP EAX						; pop highest address off the stack to use for address stack
	MOV [addrStackPointer],EAX	; store it
	
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	
	
	MOV EAX,[freeMemBlocks]		; get free memory block count into EAX
	MOV EBX,1024				; we are going to divide by 1024 to get the number of 4kb pages we need
								; for the address stack. we can fit 1024 4-byte addresses in each page of stack.
	
	MOV EDX,0					; clear EDX for remainder
	DIV EBX						; divide EAX by EBX
	
	INC EAX						; increment the page count to be sure we have a big enough stack
	
	MOV ECX,EAX					; put the page count into ECX for the upcoming loop
	

	.allocateAddressStack:		; allocate pages for the address stack
	JECXZ .doneWithAddresses	; jump here when done allocating pages
	DEC ECX						; decrement page counter
	
	POP EAX						; get another address to make room for the address stack
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	
	JMP .allocateAddressStack	; loop back to allocate more space

	.doneWithAddresses:			; jump here when done allocating pages for address stack
	
	
;------------------------------
; SETUP KERNEL STACK
;------------------------------

	MOV ECX,KSTACK_BLOCKS		; load ECX with number of pages to use for the kernel stack
	
	POP EAX						; pop address to use as kernel stack
	MOV [kStackPointer],EAX		; store it
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	DEC ECX						; decrement blocks left for kernel stack
	
	
	.allocateKernelStack:		; allocate pages for the kernel stack
	JECXZ .doneWithKernelStack	; jump here when done allocating pages
	DEC ECX						; decrement page counter
	
	POP EAX						; get another address to make room for the stack
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	
	JMP .allocateKernelStack	; loop back to allocate more space
	
	.doneWithKernelStack:		; jump here when done allocating the kernel stack
	
	
	
;------------------------------
; STORE FREE MEMORY ADDRESSES
;------------------------------

	;; here we are going to get the rest of the free addresses and push them onto the 
	;  address stack we just created. this way addresses can be popped off the stack from
	;  lowest physical address to highest
	
	MOV ECX,[freeMemBlocks]		; load number of free memory blocks into ECX
	
	
	StoreAddress:				; jump here to store the next address
		JECXZ .done				; when we have stored all the addresses, we're done
		DEC ECX					; decrement block counter
		
		POP EAX					; get the next available memory address off the stack
		
		
		MOV EDX,ESP				; store current stack pointer in EDX while we change the stack pointer
		
		
		; change the stack pointer to top of address stack:
		MOV ESP,[addrStackPointer]
		
		PUSH EAX				; push the address onto the address stack
		
		; store top of address stack:
		MOV [addrStackPointer],ESP
		
		MOV ESP,EDX				; restore stack pointer
		
		
		JMP StoreAddress		; jump back to get the next address
		
	.done:						; jump here when we're done storing free addresses
	
	
	
	
;------------------------------
; INITIALIZE PAGING
;------------------------------

	
	MOV EAX,VIR_KERNEL_POS		; desired virtual kernel location must be in EAX
	MOV EBX,[kernelSize]		; kernel size must be in EBX
	
	MOV ECX,[kStackPointer]		; physical location of kernel stack must be in ECX
	MOV EDX,KSTACK_BLOCKS		; number of pages used by the kernel stack must be in EDX
	
	MOV ESI,[addrStackPointer]	; pointer to the address stack must be in ESI

	
	;; defined in 'paging_32.asm':
	CALL InitPaging				; initialize page directory and page tables
	; after calling this the variable addrStackPointer will be invalid
	
	
	MOV [pageDirectoryLoc],EAX	; EAX returns the physical/virtual location of the page directory
	MOV [freeVirtualAddr],EBX	; EBX returns the first free virtual address
	MOV [kStackVirPointer],ECX	; ECX returns the virtual address of the kernel stack
	MOV [aStackVirPointer],EDX	; EDX returns the virtual address of the address stack
	

	
;------------------------------
; ENABLE PAGING
;------------------------------	

	CLI							; disable interrupts

	MOV EAX,[pageDirectoryLoc]	; get location of page directory into EAX
	MOV CR3,EAX					; put it in the CR3 register
	
	MOV EAX,CR0					; get value of CR0
	OR EAX,80000000h			; set paging bit
	MOV CR0,EAX					; put it back into CR0
	
	MOV EAX,[kStackVirPointer]	; get kernel stack location into EAX
	MOV ESP,EAX					; and set stack pointer to kernel stack
	
	STI							; re enable interrupts
	

	MOV ESI,strPaging			; get paging string into ESI
	CALL PrintString			; print it
	

	
;------------------------------
; ALLOCATE MEMORY FOR TSS
;------------------------------	
	
	MOV EAX,[aStackVirPointer]	; get address of address stack
	MOV EBX,[EAX]				; get first free physical address into EBX
	ADD DWORD [aStackVirPointer],4	; point address stack to next physical address
	
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	
	
	MOV EAX,[freeVirtualAddr]	; put virtual location into EAX
	ADD DWORD [freeVirtualAddr],PAGE_SIZE	; make sure free address is pointing to next page
	MOV [tssLoc],EAX			; store address in EAX as location of the TSS
	
	;; EBX is set
	MOV ECX,11b					; flags: present bit, read/write bit
	MOV EDX,[pageDirectoryLoc]	; get the directory table's location into EDX
	
	CALL MapPage				; map the page

	
;------------------------------
; ALLOCATE TSS PERMISSION MAP
;------------------------------	
	
	MOV EAX,[aStackVirPointer]	; get address of address stack
	MOV EBX,[EAX]				; get first free physical address into EBX
	ADD DWORD [aStackVirPointer],4	; update address stack to remove address
	
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	
	
	MOV EAX,[freeVirtualAddr]	; put virtual location into EAX
	ADD DWORD [freeVirtualAddr],PAGE_SIZE	; make sure free address is pointing to next page
	MOV [tssPermMap],EAX			; store address in EAX as location of the permission map
	
	;; EBX is set
	MOV ECX,11b					; flags: present bit, read/write bit
	MOV EDX,[pageDirectoryLoc]	; get the directory table's location into EDX
	
	CALL MapPage				; map the page

	
	
	MOV EAX,[aStackVirPointer]	; get address of address stack
	MOV EBX,[EAX]				; get first free physical address into EBX
	ADD DWORD [aStackVirPointer],4	; update address stack to remove address
	
	DEC DWORD [freeMemBlocks]	; decrement free block counter
	
	
	MOV EAX,[freeVirtualAddr]	; put virtual location into EAX
	ADD DWORD [freeVirtualAddr],PAGE_SIZE	; make sure free address is pointing to next page
	;; EBX is set
	MOV ECX,11b					; flags: present bit, read/write bit
	MOV EDX,[pageDirectoryLoc]	; get the directory table's location into EDX
	
	CALL MapPage				; map the page
	
;------------------------------
; PRINT DRIVER INFORMATION
;------------------------------	

	;; print disk driver info:
	MOV ESI, strDiskDrv1		; get address of first driver string
	CALL PrintString			; print the string
	MOV ESI, dDriverName		; get address of the name of the driver
	CALL PrintString			; print it
	MOV ESI, strDiskDrv2		; get address of second driver string
	CALL PrintString			; print the string
	MOV EAX,[dDriverSize]		; get the driver size
	CALL PrintNumber			; print the number
	MOV ESI, strDiskDrv3		; get address of third driver string
	CALL PrintString			; print the string
	
	;; print filesystem driver info:
	MOV ESI, strFSDrv1			; get address of first driver string
	CALL PrintString			; print the string
	MOV ESI, fsDriverName		; get address of the name of the driver
	CALL PrintString			; print it
	MOV ESI, strFSDrv2			; get address of second driver string
	CALL PrintString			; print the string
	MOV EAX,[fsDriverSize]		; get the driver size
	CALL PrintNumber			; print the number
	MOV ESI, strFSDrv3			; get address of third driver string
	CALL PrintString			; print the string
	
	
	
	
;------------------------------
; READ KERNEL FROM DISK
;------------------------------	
	
	MOV EBX,[kernelBlock]		; get the kernel block number on disk
	MOV ECX,[kernelSize]		; get the kernel size in bytes
	MOV EDX,VIR_KERNEL_POS		; get the location in memory where kernel is to be read
	
	CALL ReadFileToMem			; read the kernel from disk into memory

	
	

	
	
;------------------------------
; ENABLE KEYBOARD
;------------------------------	

	;; defined in 'keyboard_32.asm'
	CALL KeyboardInit
	
	
	
;------------------------------
; BEGIN EXECUTING KERNEL
;------------------------------	

	MOV ESI,strBootMenu				; get the menu access string into ESI
	CALL PrintString				; print it
	

	;; wait until the timer is up to give user time to press menu key
	;  then execute the kernel

	MOV ESI,strExec1				; get the executing string into ESI
	CALL PrintString				; print it
	
	
	MOV ECX,EXEC_PAUSE				; get the number of seconds to pause into ECX
	
	
	.execPause:						; begin loading the kernel
	
	JECXZ .execKernel				; if we waited enough seconds, go ahead and load the kernel

	CALL SleepSecond				; sleep for one second
	DEC ECX							; decrement second counter
	
	MOV ESI,strExec2				; get the period into ESI
	CALL PrintString				; and print it
	
	
	CALL GetLastKey					; get the last key pressed into AL
	
	
	CMP AL,MENU_KEY_CODE			; see if the key is the menu key
	JE .execMenu					; if it was, enter the menu
	
	JMP .execPause					; go back for another pause
	
	
	
	.execKernel:					; jump here to execute the kernel
	
	CALL ClearScreen				; clear the screen
	
	MOV EAX,0						; set default mode	
	
	JMP EnterKernel					; enter the kernel
	
	
	.execMenu:						; jump here to load the kernel loader menu
	
	CALL ClearScreen				; clear the screen
	
	CALL ExecuteMenu				; execute the menu
	
	JMP EnterKernel					; enter the kernel
	
	

	
;------------------------------
; KERNEL ENTRY
;------------------------------	

; EAX should be set to kernel mode of execution at this point
EnterKernel:						; jump here to enter the kernel
	
	CLI								; interrupts should be disabled when we enter kernel
	
	
	;; push everything on the stack that is supposed to be on the stack
	
	; store kernel execution mode:
	PUSH EAX
	
	; store memory size in KB:
	MOV EAX,[memSize]
	PUSH EAX
	
	; store total count of memory pages:
	MOV EAX,[memBlocks]
	PUSH EAX
	
	; store free memory pages:
	MOV EAX,[freeMemBlocks]
	PUSH EAX
	
	; store address stack pointer:
	MOV EAX,[aStackVirPointer]
	PUSH EAX
	
	; store pointer to page directory:
	MOV EAX,[pageDirectoryLoc]
	PUSH EAX
	
	; store address of device driver name:
	MOV EAX,dDriverName
	PUSH EAX
	
	; store pointer to device driver:
	MOV EAX,0	; temporary
	PUSH EAX
	
	; store address of filesystem driver name:
	MOV EAX,fsDriverName
	PUSH EAX
	
	; store pointer to filesystem driver:
	MOV EAX,0	; temporary
	PUSH EAX
	
	
	; store address of tss permission map
	MOV EAX,[tssPermMap]
	PUSH EAX
	
	
	; store address of tss:
	MOV EAX,[tssLoc]
	PUSH EAX
	

	MOV EDX,VIR_KERNEL_POS			; get kernel location into EDX

	JMP EDX							; jump to kernel entry
	
	
	
;------------------------------
; HANG SYSTEM
;------------------------------	

	Hang:						; label provided to hang system here
		JMP Hang



