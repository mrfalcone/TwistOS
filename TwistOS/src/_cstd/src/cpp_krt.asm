;========================================================================
; cpp_krt.asm 
; ----------------------------------
; C++ runtime for system kernel. Linked with kernel object code in order
; to execute kernel. This is the entry point of the kernel from the kernel
; loader. Expects stack to contain all items in the BootStruct, after the
; virtual location of the task state segment. Also expects that paging is already
; enabled, the kernel is loaded at virtual address 0xC0000000, and the
; drivers for the boot filesystem and boot device are already loaded into
; memory. This code also sets up the GDT and TSS used by the kernel, and defines the
; standard C variable, errno. Lastly, this code calls function int main() of
; the kernel, passing it a pointer to the BootStruct.
;
;
;
; -- Assembled with NASM 2.06rc2 --
; Author   : Mike Falcone
; Email    : mr.falcone@gmail.com
; Modified : 05/20/2009
;========================================================================


;; When this code is first executed, stack should be set up like this:
;  DWORD - kernel execution mode
;  DWORD - total physical memory in KB
;  DWORD - total usable physical memory pages
;  DWORD - total free physical memory pages
;  DWORD - address of stack holding all free physical addresses
;  DWORD - location of the page directory table in memory
;  DWORD - null terminated string address of device driver filename
;  DWORD - address of start of device driver file
;  DWORD - null terminated string address of filesystem driver filename
;  DWORD - address of start of filesystem driver file
;  DWORD - address of ChangeVideoMode procedure
;  DWORD - location of tss i/o permission bitmap (2 contiguous pages)
;  DWORD - location of task state segment memory page		<--- *** TOP OF STACK ***




[BITS 32]

;------------------------------
; GLOBALS
;------------------------------
[GLOBAL ExecutionPoint]			; main execution point of program, needed by linker
[GLOBAL __gxx_personality_v0]	; required for C++ programs
[GLOBAL _setErrno]
[GLOBAL _getErrno]
[GLOBAL SetupVM86Task]
;------------------------------



;------------------------------
; EXTERNAL LABELS
;------------------------------
[EXTERN main]					; main() function that must be in source

; variables from the linker for constructors and destructors
[EXTERN ctorsStart]
[EXTERN ctorsEnd]
[EXTERN dtorsStart]
[EXTERN dtorsEnd]
;------------------------------



;------------------------------
; DATA
;------------------------------
[SECTION .data]


;; a pointer to this struct will be sent to the main() function of the kernel.
;  it contains information needed by the kernel from the kernel loader
BootStruct:
	.execMode			DD 0	; kernel's execution mode
	.memInKB			DD 0	; total installed RAM in KB
	.totalPages			DD 0	; total number of available memory pages upon boot
	.freePages			DD 0	; number of free physical memory pages
	.addrStackPointer	DD 0	; pointer to the top of the address stack
	.pageDirPointer		DD 0	; pointer to the page directory table
	.strDevDriver		DD 0	; null terminated string address of device driver
	.devDriverPointer	DD 0	; pointer to the device driver
	.strFSDriver		DD 0	; null terminated string address of filesystem driver
	.fsDriverPointer	DD 0	; pointer to the filesystem driver



errNo	DD 0					; C standard variable errno


tssLoc	DD 0					; location of the TSS


;; describe the global descriptor table
StartGDT:					; mark the beginning of the GDT
	;; null segment
	 DQ 0						; first 64 bits should be 0
	
	;; ring 3 code segment
	 DW 0FFFFh					; LIMIT       : bits 0-15 of limit (0xBFFFF)
	 DW 0						; BASE LOW    : 0
	 DB 0						; BASE MID    : 0
	 DB 11111010b				; ACCESS      : usermode, code segment, nonconforming, readable
	 DB 11001101b				; GRANULARITY : bits 0-3 are bits 16-19 of limit
	 DB 0						; BASE HI     : 0
	
	;; ring 3 data segment
	 DW 0FFFFh					; LIMIT       : bits 0-15 of limit (0xBFFFF)
	 DW 0						; BASE LOW    : 0
	 DB 0						; BASE MID    : 0
	 DB 11110010b				; ACCESS      : usermode, data segment, expands down, writable
	 DB 11001101b				; GRANULARITY : bits 0-3 are bits 16-19 of limit
	 DB 0						; BASE HI     : 0
	
	;; ring 0 code segment
	 DW 0FFFFh					; LIMIT       : bits 0-15 of limit (0xFFFFF)
	 DW 0						; BASE LOW    : 0
	 DB 0						; BASE MID    : 0
	 DB 10011010b				; ACCESS      : kernelmode, code segment, nonconforming, readable
	 DB 11001111b				; GRANULARITY : bits 0-3 are bits 16-19 of limit
	 DB 0						; BASE HI     : 0
	
	;; ring 0 data segment
	 DW 0FFFFh					; LIMIT       : bits 0-15 of limit (0xFFFFF)
	 DW 0						; BASE LOW    : 0
	 DB 0						; BASE MID    : 0
	 DB 10010010b				; ACCESS      : kernelmode, data segment, expands down, writable
	 DB 11001111b				; GRANULARITY : bits 0-3 are bits 16-19 of limit
	 DB 0						; BASE HI     : 0
	
	
	;; CPU0 task state segment
	TSS0:
	 DW 3000h					; bits 0-15 of segment limit
	 .baseLow DW 0				; bits 0-15 of base, will be set upon execution
	 .baseMid DB 0				; bits 16-23 of base
	 DB 10001001b				; set type, set priv level to 0, set present bit
	 DB 0						; unused bits
	 .baseHi  DB 0				; bits 24-31 of base
	
	;; CPU1 task state segment
	TSS1:
	 DW 7FFh					; bits 0-15 of segment limit (2047)
	 .baseLow DW 0				; bits 0-15 of base, will be set upon execution
	 .baseMid DB 0				; bits 16-23 of base
	 DB 10001001b				; set type, set priv level to 0, set present bit
	 DB 0						; unused bits
	 .baseHi  DB 0				; bits 24-31 of base
	
	
	EndGDT:						; mark the end of the GDT so size can be determined

	
	GDTPointer:					; pointer to the GDT
	.size	DW EndGDT-StartGDT-1
	.offset	DD 0




;------------------------------
; PROCEDURES
;------------------------------
[SECTION .text]


; PROCEDURE: ExecutionPoint -- Entry point into kernel application. Sets up TSS, GDT, BootStruct,
;								initiates constructors, and calls int main().
ExecutionPoint:
	
	
	;; setup tss
	POP EAX						; get TSS start location
	POP EBX						; get io permission map start location
	
	CALL SetupTSS
	
	
	CALL InstallGDT				; install the GDT
	
	
	MOV AX,28h					; TSS segment selector as defined in GDT
	LTR AX						; load the task register with selector
	
	
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.fsDriverPointer],EAX

	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.strFSDriver],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.devDriverPointer],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.strDevDriver],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.pageDirPointer],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.addrStackPointer],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.freePages],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.totalPages],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.memInKB],EAX
	
	POP EAX						; get value off stack
	; store it:
	MOV [BootStruct.execMode],EAX
	
	


	;; initialize constructors
	InitCtors:					; this loop initializes the constructors
		MOV EAX,ctorsStart		; get address of start of constructors
		JMP .testEnd			; test to see if we're at the end of the constructors
		
		.call:					; call the constructor and increase the constructor pointer
		CALL [EAX]				; execute the constructor
		ADD EAX,4				; add 4 bytes to the current constructor pointer to point at next ctor
		
		.testEnd:				; test to see if this is the end of constructors
		CMP EAX,ctorsEnd		; compare to end address
		JB .call				; if not at the end, call the constructor


	
	
	MOV EAX,BootStruct			; get pointer to boot struct
	PUSH EAX					; store pointer to boot struct on stack
	
	CALL main					; call function main()
	
	
	
	;; we should never return from the kernel, so if we do, just hang
	.hang:
		JMP .hang

RET


; PROCEDURE: InstallGDT -- Installs the GDT and flushes segment registers.
;
InstallGDT:
	
	MOV EAX,StartGDT
	MOV [GDTPointer.offset],EAX
	
	PUSHAD
	LGDT [GDTPointer]			; load the GDT
	POPAD

	
	
	JMP 18h:.ReloadRegs			; set CS
	
	.ReloadRegs:				; jump here to reload registers
	
	
	MOV EAX,20h					; set EAX to kernel data segment identifier
	MOV DS,EAX					; set DS to start of data
	MOV ES,EAX					; set ES to start of data
	MOV FS,EAX					; set FS to start of data
	MOV GS,EAX					; set GS to start of data
	MOV SS,EAX					; set SS to start of data

	
RET



; PROCEDURE: SetupTSS -- Sets up the TSS and its I/O permission map. EAX must
;							be address of TSS start. EBX must be starting address
;							of 2 page permission map.
SetupTSS:

	MOV [tssLoc],EAX			; store tss base
	
	;; setup entry in the GDT
	MOV [TSS0.baseLow],AX		; store low word of tss loc
	SHR EAX,16					; shift tss loc right by a word so we can access high word
	MOV [TSS0.baseMid],AL		; store mid byte of tss loc
	MOV [TSS0.baseHi],AH		; store high byte of tss loc
	
	
	MOV EAX,[tssLoc]			; get tss base
	MOV ECX,104					; 104 bytes in the TSS
	
	.clearTSS:					; this loop clears the TSS to 0
	JECXZ .doneClearingTSS
	DEC ECX
	
	MOV [EAX],BYTE 0			; set byte to 0
	INC EAX						; increase position in TSS
	
	JMP .clearTSS				; keep clearing
	
	.doneClearingTSS:
	
	
	MOV EAX,[tssLoc]			; get tss base

	MOV ECX,EBX					; get permission map start into ECX
	SUB ECX,EAX					; subtract base of tss
	
	MOV [EAX+102],CX			; store 16 bit offset in io map address field
	
	MOV ECX,8192+32				; number of bytes in io map plus 32 for the int redirect map
	MOV EDI,EBX					; get permission map address
	SUB EDI,32					; subtract 32 to get the base of the int redirect map
	
	.clearMap:					; this loop sets all bits in the map to 0
	JECXZ .doneClearingMap		; when we set all the bytes, we're done
	SUB ECX,4					; decrement byte counter by 4
	
	MOV DWORD[EDI],0			; set the current dword in map to 0
	ADD EDI,4					; increase position in map
	
	JMP .clearMap				; keep clearing
	
	.doneClearingMap:
	MOV [EDI-1],BYTE 0FFh		; set last byte in map to FFh
	
	
RET


;; set up TSS to run an upcoming vm86 task
; update references
SetupVM86Task:

	MOV ECX,ESP					; store current ESP in ECX so we can put it in the TSS

	PUSHAD

	MOV EDX,[tssLoc]			; get tss base
	
	MOV [EDX+4],ECX				; store ring 0 esp in tss
	
	MOV EBX,SS					; get stack segment
	MOV [EDX+8],BX				; store as ring 0 ss
	
	
	MOV EBX,CR3					; get value of CR3 (page dir table location)
	MOV [EDX+28],EBX			; store it in tss
	
	

	
	; MOV EBX,20h					; set EBX to set segment regs in tss
	; MOV [EAX+72],BX				; store in TSS as ES
	; MOV [EAX+80],BX				; store in TSS as SS
	; MOV [EAX+84],BX				; store in TSS as DS
	; MOV [EAX+88],BX				; store in TSS as FS
	; MOV [EAX+92],BX				; store in TSS as GS
	
	; MOV EBX,18h
	; MOV [EAX+76],BX				; store in TSS as CS


	
	
	
	MOV [EAX+12],DWORD 0FFFFh	; store 0xFFFF as ring 1 esp
	MOV [EAX+20],DWORD 0FFFFh	; store 0xFFFF as ring 2 esp
	
	
	MOV BX,DS					; get current DS to use for stack segment
	DEC BX						; decrement to use for SS
	
	MOV [EAX+16],BX				; store as ring 1 ss
	MOV [EAX+24],BX				; and ring 2 ss
	
	
	

	
	; MOV EBX,0					; clear EBX
	; MOV BX,[EAX+102]			; get offset of io permission map
	; ADD EAX,EBX					; add it to start of TSS, now EAX is start of io bitmap
	; SUB EAX,32					; subtract 32 bytes from bitmap base to get int redirect map base
	
	;MOV [EAX+10],BYTE 0FFh	; set bit 1 of byte 2, this enabled int 10h to be called by VM86 tasks
	
	; mov ecx,32
	; .loop:
	; jecxz .done
	; dec ecx
	; mov [eax],byte 0FFh
	; inc eax
	
	; jmp .loop
	; .done:
	
	

	
	POPAD

	
	
 RET





;------------------------------
; REQUIRED FOR C++
;------------------------------

_setErrno:
	;; this procedure will be called by a C program so parameter is passed on stack before return value
	MOV EAX,[ESP+8]				; get the errno parameter
	
	MOV [errNo],EAX				; set it
	
RET


_getErrno:

	MOV EAX,[errNo]				; get errno into EAX to return
	
RET


__gxx_personality_v0:
	
	; required for linking c++ programs

RET

