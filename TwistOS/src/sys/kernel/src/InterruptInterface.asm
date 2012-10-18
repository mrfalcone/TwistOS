;========================================================================
; InterruptInterface.asm 
; ----------------------------------
; Implementation of the InterruptInterface class. Sets up the IDT and
; provides procedure for aborting the system.
;
; C++ header: InterruptInterface.h
;
;
; -- Assembled with NASM 2.06rc2 --
; Author   : Mike Falcone
; Email    : mr.falcone@gmail.com
; Modified : 05/18/2009
;========================================================================


[BITS 32]


;------------------------------
; GLOBALS
;------------------------------
;; functions declared in "InterruptInterface.h"
[GLOBAL _ZN18InterruptInterfaceC2EM11TwistKernelFivEMS0_FviE]
[GLOBAL _ZN18InterruptInterfaceC1EM11TwistKernelFivEMS0_FviE]
[GLOBAL _ZN18InterruptInterface5AbortEPKc]
[GLOBAL _ZN18InterruptInterface11GetVecLINT0Ev]
[GLOBAL _ZN18InterruptInterface11GetVecLINT1Ev]
[GLOBAL _ZN18InterruptInterface15GetVecAPICErrorEv]
[GLOBAL _ZN18InterruptInterface19GetVecThermalSensorEv]
[GLOBAL _ZN18InterruptInterface15GetVecAPICTimerEv]
;------------------------------



;------------------------------
; EXTERNAL LABELS
;------------------------------
[EXTERN SetupVM86Task]

;------------------------------


;------------------------------
; CONSTANTS
;------------------------------
;; constants used for printing screen of death
VIDEO_MEMORY	EQU 000B8000h	; start of video memory
SCREEN_COLS		EQU 80			; number of columns on the screen
SCREEN_ROWS		EQU 25			; number of rows on the screen
HEAD_ATTR		EQU 101111b		; header text attribute
TEXT_ATTR		EQU 101111b		; text attribute
ESTR_ATTR		EQU 101110b		; error string text attribute


;; constants for IDT entries
ENTRYCOUNT		EQU 255			; total number of IDT entries existing
ENTRYSIZE		EQU 8			; size in bytes of each entry

CODE_SELECTOR	EQU 18h			; code selector to use for IDT entries
INT_FLAGS		EQU 10001110b	; flags for normal ISR
TRP_FLAGS		EQU 10001111b	; flags for trap gate
RES_FLAGS		EQU 00000000b	; flags for reserved ISR, present bit cleared
;------------------------------



;------------------------------
; IDT STRUCTURE
;------------------------------

;; struct for entry in the IDT
STRUC Entry
	.baseLow	RESW 1			; low word of ISR base
	.selector	RESW 1			; code selector
	.reserved	RESB 1			; reserved
	.flags		RESB 1			; ISR flags
	.baseHigh	RESW 1			; high word of ISR base
ENDSTRUC
;------------------------------



;------------------------------
; MACROS
;------------------------------

; MACRO: INT_CODE -- macro used in ISR to call int occurred function. Param is int number.
;
%macro INT_CODE 1
	PUSHAD						; push registers onto stack
	
	MOV EAX,%1					; get interrupt number into EAX
	PUSH EAX					; push it to stack as a parameter for the C++ function
	PUSH EAX					; push it again
	
	MOV EAX,[ptrIntOccurFunc]	; get address of function
	CALL EAX					; and call it
	
	ADD ESP,8					; fix stack to ignore both items we pushed
	
	POPAD						; restore registers
%endmacro


; MACRO: ABORT_CODE -- aborts the system and prints the screen of death with string pointed to by param.
;
%macro ABORT_CODE 1

	MOV ESI,%1					; put string pointer in ESI
	CALL PrintScreenOfDeath		; print the screen of death
	%%hang:						; hang system
		JMP %%hang
%endmacro


; MACRO: IDTENTRY -- sets up an IDT entry at EDX. Param 1 is address of ISR, param 2 is flags byte.
;
%macro IDTENTRY 2

	MOV EAX,%1					; get address of ISR into EAX
	MOV EBX,EAX					; copy it to EBX too
	SHR EBX,16					; shift high word right so it is accessible in BX
	
	MOV [EDX+Entry.baseLow],AX	; put the low word of the base into entry
	MOV [EDX+Entry.baseHigh],BX	; put the high word of the base into entry
	
	; install flags
	MOV [EDX+Entry.flags],BYTE %2
	
	ADD EDX,ENTRYSIZE			; increase EDX by size of this entry
	
%endmacro


; MACRO: EMU_BIOS_INT -- emulates the specified bios interrupt in VM86 mode. Called during GPF.
;
%macro EMU_BIOS_INT 1
	MOV ESI,%1					; get interrupt number
	SHR ESI,2					; get pointer to ISR address in interrupt table
	
	POP EAX						; get old IP into EAX
	ADD EAX,2					; we will return 2 from this IP
	POP EBX						; get old CS into EBX
	POP ECX						; get old EFLAGS into ECX
	
	POP EDX						; get ring 3 stack pointer
	
	SUB EDX,2					; pushing 2 bytes onto stack
	MOV [EDX],CX				; push FLAGS
	
	SUB EDX,2					; pushing 2 bytes onto stack
	MOV [EDX],BX				; push CS
	
	SUB EDX,2					; pushing 2 bytes onto stack
	MOV [EDX],AX				; push IP

	
	PUSH EDX					; store ring 3 esp back on stack
	
	
	OR ECX,20000h				; make sure VM bit of EFLAGS is set
	PUSH ECX					; push EFLAGS
	
	MOV EAX,0					; clear EAX
	
	LODSW						; get offset of ISR address into AX
	MOV EBX,EAX					; put offset into EBX
	
	LODSW						; get segment of ISR address into AX
	
	PUSH EAX					; push segment as CS
	PUSH EBX					; push offset as IP
%endmacro
;------------------------------





;------------------------------
; STRINGS
;------------------------------
[SECTION .rodata]				; begin read only data section

;; strings
strFatal		DB " Fatal System Error!!!",10
				DB "อออออออออออออออออออออออ",10,10,10,0

strFailed		DB "   The kernel has failed due to the following error:",10,0
strRsnBegin		DB "    ฏ ",0
strShutdown		DB 10,10,"   In order to prevent damage to your system, your computer must be shut down.",0


;; fault error strings
estrUnknown		DB "An unknown error has occurred.",0
estrDivZero		DB "Divide-by-zero error.",0
estrOverflow	DB "Overflow error.",0
estrInvalidOPC	DB "Invalid opcode error.",0
estrNoDev		DB "Device not available.",0
estrDblFault	DB "CPU double fault.",0
estrStackFault	DB "Stack fault exception.",0
estrGPF			DB "Unhandled general protection fault.",0
estrPageFault	DB "Could not recover from page fault.",0


;------------------------------
; DATA
;------------------------------
[SECTION .data]					; begin data section

;; function pointers
ptrPFOccurFunc		DD 0		; pointer to C++ function to be called when a page fault occurs
ptrIntOccurFunc		DD 0		; pointer to C++ function to be called when an interrupt occurs


;; important interrupt numbers
;  these numbers are required in setting up the APIC
vecLINT0			DD 0		; num of interrupt to call when an interrupt is signaled at LINT0
vecLINT1			DD 0		; num of interrupt to call when an interrupt is signaled at LINT1
vecAPICError		DD 0		; num of interrupt to call when apic detects an error
vecThermalSensor	DD 0		; num of interrupt to call when thermal sensor interrupts
vecAPICTimer		DD 0		; num of interrupt to call when apic timer goes off




;; reserve enough space for the IDT
IDTStart:
	%rep ENTRYCOUNT
		DW 0						; base low
		DW CODE_SELECTOR			; code selector
		DB 0						; reserved
		DB RES_FLAGS				; flags, reserved by default
		DW 0						; base high
	%endrep
	

;; pointer used to load the table with LIDT
IDTPointer:							; pointer used in installing the IDT
	DW (ENTRYCOUNT*ENTRYSIZE)		; define limit
	DD IDTStart						; define base




;------------------------------
; GLOBAL C++ FUNCTIONS
;------------------------------
[SECTION .text]					; begin code section


;; InterruptInterface(BOOL (TwistKernel::*onPageFault)(void), void (TwistKernel::*onInterrupt)(int))
_ZN18InterruptInterfaceC2EM11TwistKernelFivEMS0_FviE:
_ZN18InterruptInterfaceC1EM11TwistKernelFivEMS0_FviE:
	
	
	PUSH EBP					; store EBP so it will remain unchanged
	MOV EBP,ESP					; set EBP to point to the stack so we can access variables
	PUSH EBX					; store EBX to keep it unchanged
	PUSH ESI					; store ESI to keep it unchanged
	PUSH EDI					; store EDI to keep it unchanged
	
	
	MOV EAX,[EBP+12]			; get second variable into EAX (pointer to page fault occurred function)
	MOV [ptrPFOccurFunc],EAX	; store pointer
	
	
	MOV EAX,[EBP+20]			; get third variable into EAX (pointer to interrupt occurred function)
	MOV [ptrIntOccurFunc],EAX	; store pointer
	
	CLI							; be sure interrupts are disabled
	
	CALL InstallIDT				; install the IDT and stores interrupt numbers required by APIC
	
	
	POP EDI						; restore original EDI
	POP ESI						; restore original ESI
	POP EBX						; restore original EBX
	MOV ESP,EBP					; restore original stack pointer
	POP EBP						; restore original EBP

RET



;; void Abort(const char *reason)
_ZN18InterruptInterface5AbortEPKc:


	MOV ESI,[ESP+8]				; get error string
	
	CALL PrintScreenOfDeath		; print the screen of death
	
	
	.hang:						; the system will hang now
		JMP .hang

RET


;; int GetVecLINT0()
_ZN18InterruptInterface11GetVecLINT0Ev:
	
	MOV EAX,[vecLINT0]			; get interrupt number into EAX to return
RET


;; int GetVecLINT1()
_ZN18InterruptInterface11GetVecLINT1Ev:
	
	MOV EAX,[vecLINT1]			; get interrupt number into EAX to return
RET


;; int GetVecAPICError()
_ZN18InterruptInterface15GetVecAPICErrorEv:
	
	MOV EAX,[vecAPICError]		; get interrupt number into EAX to return
RET


;; int GetVecThermalSensor()
_ZN18InterruptInterface19GetVecThermalSensorEv:
	
	MOV EAX,[vecThermalSensor]	; get interrupt number into EAX to return
RET


;; int GetVecAPICTimer()
_ZN18InterruptInterface15GetVecAPICTimerEv:
	
	MOV EAX,[vecAPICTimer]		; get interrupt number into EAX to return
RET



;------------------------------
; ISR'S
;------------------------------

;; ISR used on interrupts to immediately abort system
AbortInt:
	ABORT_CODE estrUnknown		; call abort macro
IRETD


;; ISRs 0-31 for processor exceptions
Int0:
	ABORT_CODE estrDivZero		; call abort macro
IRETD


Int4:
	ABORT_CODE estrOverflow		; call abort macro
IRETD


Int6:
	ABORT_CODE estrInvalidOPC	; call abort macro
IRETD


Int7:
	ABORT_CODE estrNoDev		; call abort macro
IRETD


Int8:
	ABORT_CODE estrDblFault		; call abort macro
IRETD


Int12:
	ABORT_CODE estrStackFault	; call abort macro
IRETD


;; general protection fault
Int13:
	PUSH ESI
	
	MOV ESI,SS					; get kernel stack segment selector
	MOV DS,ESI					; use it as data segment selector for kernel
	MOV ES,ESI					; and extra segment
	
	
	JMP .startGPFHandler
	
	
	.eax			DD 0
	.ebx			DD 0
	.ecx			DD 0
	.edx			DD 0
	.esi			DD 0
	.edi			DD 0
	
	.restoreRegs	DB 0
	
	
	
	.startGPFHandler:
	
	POP ESI
	
	;; store register values
	MOV [SS:.eax],EAX
	MOV [SS:.ebx],EBX
	MOV [SS:.ecx],ECX
	MOV [SS:.edx],EDX
	MOV [SS:.esi],ESI
	MOV [SS:.edi],EDI
	
	MOV [.restoreRegs],BYTE 1
	
	
	
	POP EDX						; get error code off stack
	
	MOV EAX,[ESP]				; get return EIP off stack
	MOV EBX,[ESP+4]				; get CS off stack
	MOV ECX,[ESP+8]				; get EFLAGS off stack
	

	
	TEST ECX,20000h				; see if the VM86 bit is set
	JNZ .vm86Monitor			; if it is, handle it
	
	
	MOV ESI,EAX					; get address of byte causing exception
	
	MOV EAX,0					; clear EAX
	LODSB						; get byte into AL
	
	mov ecx,10b
		mov edx,0
		call PrintNumber
		jmp .j
	
	;; if we cannot handle the GPF, abort
	.abort:						; jump here to abort the system
	ABORT_CODE estrGPF			; call abort macro
	
	
	
	
	;; handle virtual 8086 interrupts
	.vm86Monitor:
		JMP .start				; jump to start of code
		
		.o32	DB 0			; this will be 1 when the O32 instruction is used
		.a32	DB 0			; this will be 1 when the A32 instruction is used
		.eipOff	DB 0			; this will store the number of bytes we moved passed EIP
		
		.start:					; start of code
		MOV [.o32],BYTE 0
		MOV [.eipOff],BYTE 0
		
		
		;; find out what caused the GPF
		MOV ESI,EBX				; get CS into ESI to calculate linear address of byte causing fault
		SHL ESI,4				; multiply CS by 16 since each segment is 16 bytes
		ADD ESI,EAX				; add EIP, now ESI is linear address of byte causing the GPF
		
		MOV EAX,0				; clear EAX
		LODSB					; get byte into AL
		
		
		;; check byte at IP
		CMP AL,66h				; see if IP is O32 instruction
		JNE .checkByte
		MOV [.o32],BYTE 1		; set o32
		LODSB					; get next byte into AL
		INC BYTE [.eipOff]		; increment the eip offset
		
		
		.checkByte:
		CMP AL,0CDh				; see if the byte code was INT instruction
		JE .runInt
		
		.c1:
		CMP AL,9Ch				; see if PUSHF caused gpf
		JNE .c2
		JMP .pushf
		
		.c2:
		CMP AL,9Dh				; see if POPF caused gpf
		JNE .c3
		JMP .popf
		
		.c3:
		CMP AL,0CFh				; see if IRET caused gpf
		JNE .c4
		JMP .iret
		
		.c4:
		CMP AL,0CCh				; int3 signifies that we are leaving VM86 mode
		JNE .c5
		JMP .returnFromVM86
		
		
		.c5:
		mov ecx,1b
		mov edx,0
		call PrintNumber
		.j:
		jmp .j
		
		JMP .abort				; if not handled, abort system
		
		
		
		.runInt:				; jump here to run the interrupt that caused the exception
		LODSB					; get byte afterwards to get interrupt number into AL

		; set variable to restore registers when we exit
		MOV [.restoreRegs],BYTE 1
		
		EMU_BIOS_INT EAX
		JMP .return
		
		mov ecx,100b
		mov edx,0
		call PrintNumber
		jmp .j
		; CMP	AL,86				; see if INT 86 caused the gpf
		; JNE .abort				; if not,abort system
		; JMP .returnFromVM86		; if so, it's time to return to protected mode
		
	JMP .abort
	

	.sti:						; jump here if sti caused the exception
	POP EAX						; get return EIP
	INC EAX						; increment it since this handler is an int gate
	
	POP EBX						; get return CS
	
	POP ECX						; get EFLAGS
	OR ECX,0A0000h				; make sure VM bit of EFLAGS is set and IF is set
	
	PUSH ECX					; push EFLAGS
	PUSH EBX					; push CS
	PUSH EAX					; push return IP
	
	JMP .return					; return from exception
	
	
	
	.pushf:						; jump here if pushf caused the exception
		
		POP EAX					; get return EIP
		INC EAX					; increment it since this handler is an int gate
		MOV EBX,0				; clear EBX
		MOV BL,[.eipOff]		; get eip offset
		ADD EAX,EBX				; and add it to return EIP
		
		POP EBX					; get return CS
		
		POP ECX					; get EFLAGS
		OR ECX,20000h			; make sure VM bit of EFLAGS is set
		
		POP EDX					; get ring 3 stack pointer
		
		PUSH ECX				; store current flags
		
		CMP BYTE [.o32],1		; see if o32 is set
		JNE .pushfO16			; if not, push 16 bits
		
		SUB EDX,4				; we are adding 4 bytes to the stack
		AND ECX,0FFFFh			; only use low 16 bits
		MOV [EDX],ECX			; push FLAGS onto ring 3 stack
		JMP .pushfEnd			; push the new values to the stack
		
		.pushfO16:
		SUB EDX,2				; we are adding 2 bytes to the stack
		MOV [EDX],CX			; push FLAGS onto ring 3 stack
		
		
		.pushfEnd:
		POP ECX					; get original EFLAGS
		
		PUSH EDX				; push new ring 3 stack pointer
		PUSH ECX				; push EFLAGS
		PUSH EBX				; push CS
		PUSH EAX				; push return IP
		;mov eax,13h
	JMP .return					; return from exception
	
	
	
	.popf:						; jump here if popf caused the exception
		
		POP EAX					; get return EIP
		INC EAX					; increment it since this handler is an int gate
		MOV EBX,0				; clear EBX
		MOV BL,[.eipOff]		; get eip offset
		ADD EAX,EBX				; and add it to return EIP
		
		POP EBX					; get return CS
		POP ECX					; pop EFLAGS
		POP EDX					; get ring 3 stack pointer
		
		
		CMP BYTE [.o32],1		; see if o32 is set
		JNE .popfO16			; if not, push 16 bits
		
		
		MOV ECX,[EDX]			; pop FLAGS from ring 3 stack
		ADD EDX,4				; we are removing 4 bytes from the stack
		JMP .popfEnd			; push the new values to the stack
		
		.popfO16:
		MOV ECX,0				; clear ECX
		MOV CX,[EDX]			; pop FLAGS from ring 3 stack
		ADD EDX,2				; we are removing 2 bytes from the stack
		
		
		.popfEnd:
		PUSH EDX				; push new ring 3 stack pointer
		OR ECX,20000h			; make sure VM bit of EFLAGS is set
		PUSH ECX				; push EFLAGS
		PUSH EBX				; push CS
		PUSH EAX				; push return IP
		
		
	JMP .return					; return from exception
	
	
	
	.iret:						; jump here if iret caused the exception
		
		MOV EDX,[ESP+12]		; get ring 3 stack pointer
		
		ADD ESP,16				; pop off 16 bytes from the ring0 stack
		
		
		MOV EAX,EDX				; copy ring 3 sp to EAX
		ADD EAX,6				; pop off 6 bytes to remove IP, CS, and FLAGS
		
		PUSH EAX				; push new ring 3 stack pointer
		
		MOV ECX,0				; clear ECX
		MOV CX,[EDX+4]			; get return FLAGS from ring 3 stack
		OR ECX,20000h			; make sure VM bit of EFLAGS is set
		PUSH ECX				; push it as return flags
		
		
		MOV EAX,0				; clear EAX
		MOV AX,[EDX+2]			; get return CS from ring 3 stack
		PUSH EAX				; push it as return CS
		
		MOV AX,[EDX]			; get return IP from ring 3 stack
		PUSH EAX				; push it as return IP
		
		
		; mov ecx,07h
		; mov edx,0
		; call PrintNumber
		; jmp .j
		
		
	JMP .return					; return from exception
	
	
	
	
	.returnFromVM86:			; jump here to return to protected mode
	
	ADD ESP,40					; get all VM86-added values off the stack
	
	POP EAX						; pop a dword to see if it's the magic value
	CMP EAX,'VM86'				; value that was pushed before entering VM86 mode
	JE .return					; if it is, we can enter protected mode
	
	JMP .abort					; if it isn't right, abort
	
	
	.gotoPmode:
	ABORT_CODE estrOverflow
	MOV ECX,16					; number of times to pop from stack to find value we're looking for
	
	; .findESP:					; this loop pops from the stack until value 'VM86' is found
		; JECXZ .abort			; if we have tried all pops without finding it, there's an error
		; DEC ECX					; decrement try counter
		
		; POP EAX					; get a value from the stack
		; CMP EAX,'VM86'			; see if it's the 'VM86' value pushed before going to VM86 mode
		; JE .return				; if it is, we can return now, the stack is at the right place
	; JMP .findESP				; if not, loop back to try again
	
	
	.restoreRegValues:
	MOV EAX,[.eax]
	MOV EBX,[.ebx]
	MOV ECX,[.ecx]
	MOV EDX,[.edx]
	MOV ESI,[.esi]
	MOV EDI,[.edi]
	
	MOV [.restoreRegs],BYTE 0
	
	
	.return:
	; if restore registers variable is set, restore all the registers before returning
	CMP [.restoreRegs],BYTE 0
	JNE .restoreRegValues
	
IRETD


;; page fault exception
Int14:
	;; handle page fault
	PUSHAD						; push registers onto stack
	
	MOV EAX,[ptrPFOccurFunc]	; get address of page fault occur function
	CALL EAX					; and call it
	
	CMP EAX,0					; if 0, the page fault did not get corrected
	JNE .return					; if not zero, the page fault was corrected and we can return
	
	ABORT_CODE estrPageFault	; otherwise call abort macro
	
	.return:
	POPAD						; restore registers
IRETD


;; ISRs 32-41 for software interrupts
Int32:
	; add code for the software interrupt
	INT_CODE 32
IRETD


Int33:
	; add code for the software interrupt
	INT_CODE 33
IRETD


Int34:
	; add code for the software interrupt
	INT_CODE 34
IRETD


Int35:
	; add code for the software interrupt
	INT_CODE 35
IRETD


Int36:
	; add code for the software interrupt
	INT_CODE 36
IRETD


Int37:
	; add code for the software interrupt
	INT_CODE 37
IRETD


Int38:
	; add code for the software interrupt
	INT_CODE 38
IRETD


Int39:
	; add code for the software interrupt
	INT_CODE 39
IRETD


Int40:
	; add code for the software interrupt
	INT_CODE 40
IRETD


Int41:
	; add code for the software interrupt
	INT_CODE 41
IRETD


;; ISRs 42-46 for APIC
Int42:
	;; called when an interrupt is signaled at LINT0
	MOV EAX,0
IRETD


Int43:
	;; called when an interrupt is signaled at LINT1
	MOV EAX,0
IRETD


Int44:
	;; called when apic detects an error
	MOV EAX,0
IRETD


Int45:
	;; called when thermal sensor interrupts
	MOV EAX,0
IRETD


Int46:
	;; called when apic timer goes off
	MOV EAX,0
IRETD



;; must contain int number in esi
Int86:

	CMP ESI,10h					; video interrupt
	JE .int10h
	
	
	JMP .return					; if int isn't supported, just return
	

	.int10h:
	
	MOV EDX,'VM86'				; value to push onto stack so we can find esp to return
	PUSH EDX
	
	
	
	MOV ECX,EndChangeVideoMode-ChangeVideoMode
	MOV ESI,ChangeVideoMode
	
	MOV EDI,DS					; get data selector to make linear address of copy location
	SHL EDI,4					; multiply by 16 since each segment is 16 bytes
	
	REP MOVSB					; copy the procedure
	
	
	;; setup the tss so we can properly return from vm86 mode
	CALL SetupVM86Task			; defined in 'cpp_krt.asm'
	
	
	MOV ECX,[ESP+12]			; get EFLAGS off the stack
	OR ECX,0A0000h				; set VM and VIF bits of EFLAGS
	
	
	;; segment registers must be pushed onto the stack to enter VM86 task
	MOV EDX,DS					; get current value of DS to use for all segment regs
	PUSH EDX					; GS
	PUSH EDX					; FS
	PUSH EDX					; DS
	PUSH EDX					; ES
	DEC EDX						; get segment under data to use as stack
	PUSH EDX					; SS
	MOV EDX,0FFFFh				; set sp to end of segment
	PUSH EDX					; SP
	
	
	PUSH ECX					; store EFLAGS with VM bit set
	
	MOV EDX,DS					; new CS
	PUSH EDX					; store on stack
	
	MOV EDX,0					; new IP
	PUSH EDX					; store it on stack
	

	MOV EDX,CR4					; get the contents of CR4 into EDX
	OR EDX,1b					; set the VME flag and PVI flag
	MOV CR4,EDX					; put the value back in CR4
	
	.return:
	
IRETD



;------------------------------
; LOCAL PROCEDURES
;------------------------------

; PROCEDURE: InstallIDT -- Installs the interrupt descriptor table.
;
InstallIDT:

	MOV EDX,IDTStart			; get the start address of the IDT into EDX
	
	
	;; processor exceptions:
	IDTENTRY Int0,TRP_FLAGS		; setup IDT entry 0
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 1
	
	ADD EDX,ENTRYSIZE			; skip entry 2
	
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 3
	IDTENTRY Int4,TRP_FLAGS		; setup IDT entry 4
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 5
	IDTENTRY Int6,TRP_FLAGS		; setup IDT entry 6
	IDTENTRY Int7,TRP_FLAGS		; setup IDT entry 7
	IDTENTRY Int8,TRP_FLAGS		; setup IDT entry 8
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 9
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 10
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 11
	IDTENTRY Int12,TRP_FLAGS	; setup IDT entry 12
	IDTENTRY Int13,INT_FLAGS	; setup IDT entry 13,GPF
	IDTENTRY Int14,TRP_FLAGS	; setup IDT entry 14
	
	ADD EDX,ENTRYSIZE			; skip entry 15
	
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 16
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 17
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 18
	IDTENTRY AbortInt,TRP_FLAGS	; setup IDT entry 19
	
	ADD EDX,(12*ENTRYSIZE)		; skip remaining 12 processor exceptions
	
	
	
	;; software interrupts:
	IDTENTRY Int32,INT_FLAGS	; setup IDT entry 32
	IDTENTRY Int33,INT_FLAGS	; setup IDT entry 33
	IDTENTRY Int34,INT_FLAGS	; setup IDT entry 34
	IDTENTRY Int35,INT_FLAGS	; setup IDT entry 35
	IDTENTRY Int36,INT_FLAGS	; setup IDT entry 36
	IDTENTRY Int37,INT_FLAGS	; setup IDT entry 37
	IDTENTRY Int38,INT_FLAGS	; setup IDT entry 38
	IDTENTRY Int39,INT_FLAGS	; setup IDT entry 39
	IDTENTRY Int40,INT_FLAGS	; setup IDT entry 40
	IDTENTRY Int41,INT_FLAGS	; setup IDT entry 41
	
	
	;; APIC interrupts:
	MOV EAX,42					; get interrupt number into EAX
	MOV [vecLINT0],EAX			; and store it in variable
	IDTENTRY Int42,INT_FLAGS	; setup IDT entry 42

	MOV EAX,43					; get interrupt number into EAX
	MOV [vecLINT1],EAX			; and store it in variable
	IDTENTRY Int43,INT_FLAGS	; setup IDT entry 43

	MOV EAX,44					; get interrupt number into EAX
	MOV [vecAPICError],EAX		; and store it in variable
	IDTENTRY Int44,INT_FLAGS	; setup IDT entry 44

	MOV EAX,45					; get interrupt number into EAX
	MOV [vecThermalSensor],EAX	; and store it in variable
	IDTENTRY Int45,INT_FLAGS	; setup IDT entry 45

	MOV EAX,46					; get interrupt number into EAX
	MOV [vecAPICTimer],EAX		; and store it in variable
	IDTENTRY Int46,INT_FLAGS	; setup IDT entry 46
	
	
	
	ADD EDX,(39*ENTRYSIZE)		; skip next 39 interrupts
	
	
	
	IDTENTRY Int86,INT_FLAGS	; setup IDT entry 86 for VM86 mode
	
	
	;; finally install IDT in the processor
	LIDT [IDTPointer]			; load the interrupt descriptor table into the cpu
RET



; PROCEDURE: PrintScreenOfDeath -- Prints the screen of death using error string pointed to by ESI.
;
PrintScreenOfDeath:

	MOV EDI,0					; clear EDI
	MOV EDI,ESI					; store pointer to error string in EDI for now

	CALL ClearScreen			; clear the screen first
	
	MOV ESI,strFatal			; get fatal error string
	MOV CL,HEAD_ATTR			; get header text attribute
	CALL PrintString			; print string

	MOV ESI,strFailed			; get failed reason error string
	MOV CL,TEXT_ATTR			; get normal text attribute
	CALL PrintString			; print string

	MOV ESI,strRsnBegin			; get begining of reason string
	MOV CL,ESTR_ATTR			; get error string text attribute
	CALL PrintString			; print string
	
	MOV ESI,EDI					; get error string pointer back into ESI
	MOV CL,ESTR_ATTR			; get error string text attribute
	CALL PrintString			; print string

	MOV ESI,strShutdown			; get shutdown string
	MOV CL,TEXT_ATTR			; get normal text attribute
	CALL PrintString			; print string
	
RET



; PROCEDURE: ClearScreen -- Clears entire screen and resets cursor position.
;
ClearScreen:
	MOV EBX,VIDEO_MEMORY		; set EBX to start of video memory
	
	; define size of screen in ECX
	MOV ECX,SCREEN_COLS*SCREEN_ROWS
	
	MOV EDX,0					; clear row and column
	
	
	.cl:						; label provided to keep clearing
	 JECXZ .return				; when ECX is 0 we are done clearing
	 DEC ECX					; decrement the video memory counter
	 
	 MOV [EBX],BYTE 20h			; move the space character to video memory
	 INC EBX					; increment vid mem position
	
	 MOV [EBX],BYTE TEXT_ATTR	; normal text attribute
	 INC EBX					; increment vid mem position
	 
	 JMP .cl					; jump to cl label
	.return:
RET



; PROCEDURE: PrintString -- Prints a string to the screen. String must end with null character.
;			  				ESI must contain the address to the string. Byte 10 specifies that
;							there is a line break. DL must contain current row and DH must contain
;							current column. CL must contain the text attribute byte to use.
PrintString:

	CALL GetVidMemPos			; get the position into video memory and put in EBX
	
	MOV EAX,0					; clear EAX
	
	CLD							; clear direction flag
	
	.loop:						; label provided to parse special characters then print
	 LODSB						; copies the data in ESI to AL and increments ESI
	 CMP AL,0					; compare the character to 0, 0 marks the end of string
	 JZ .return					; if we reached the end of the string, return from proc
	 
	 
	 CMP AL,10					; see if this is a newline character
	 JNE .print					; if it's not, print the character
	 
	 ; if it is a newline character:
	 INC DL						; increase current row
	 MOV DH,0					; set the current column to 0
	 CALL GetVidMemPos			; recalculate the position in video memory
	 JMP .loop					; keep doing the loop
	 
	 
	
	 .print:
	  MOV BYTE [EBX],AL			; move the character to video memory
	  INC EBX					; increment vid mem position
	  INC DH					; increment current column
	
	  MOV BYTE [EBX],CL			; get text attribute
	  INC EBX					; increment vid mem position
	  INC DH					; increment current column

	 JMP .loop					; keep looping
	 
	.return:
RET



; PROCEDURE: GetVidMemPos -- Calculates the current position in video memory at which
;								to write data. DL must contain current row and DH must contain
;								current column. Position is returned in EBX.
GetVidMemPos:

	MOV EAX,0					; clear EAX

	MOV EBX,0					; clear EBX
	MOV BL,DL					; get the current row into EBX

	
	SHL ECX,16					; shift current text attribute enough so we can fit row and column into ECX
	MOV CL,DL					; put row at CL
	MOV CH,DH					; put column at CH
	
	
	MOV EAX,SCREEN_COLS*2		; we want to multiply to get where the current row starts in video memory
								; times two because of the attribute byte
	
	MOV EDX,0					; clear EDX
	MUL EBX						; multiply by current row, MUL instruction trashes EDX
	MOV EDX,0					; clear EDX again
	
	
	MOV DL,CL					; put row back in DL
	MOV DH,CH					; put column back in DH
	SHR ECX,16					; shift text attribute back to CL
	
	
	MOV EBX,0					; clear EBX
	MOV BL,DH					; get the current column into EBX
	ADD EAX,EBX					; add the current column
	
	
	MOV EBX,VIDEO_MEMORY		; put the start of video memory at EBX
	ADD EBX,EAX					; total equals the video memory at the current row and column

RET


; PROCEDURE: PrintNumber -- Prints decimal number on the screen as ascii characters. Must
;							contain the number in EAX. DL must contain current row and DH must contain
;							current column. CL must contain the text attribute byte to use.
PrintNumber:
	MOV EBX,0					; clear EBX
	MOV ESI,ECX					; save text attribute in ESI
	MOV ECX,0					; clear ECX, ECX will count our digits
	MOV EDI,EDX					; save print position in EDI
	MOV EDX,0					; clear EDX
	
	MOV EBX,10					; we will be dividing by 10 to get individual digits
	
		
	.parse:
	DIV EBX						; divide EAX by 10, EDX stores the remainder
	

	CMP EAX,0					; see if there's still numbers to convert
	JNE .push					; if EAX is not 0, we can continue, so go to .push
	CMP EDX,0					; see if there is a remainder available
	JE .print					; if both EAX and EDX are 0, go ahead and print
	
	.push:	
	PUSH EDX					; push the remainder onto the stack
	MOV EDX,0					; clear EDX again
	INC ECX						; increment our digit count
	JMP .parse					; continue parsing the number

	
	
	.print:						; begin printing
	
	MOV EDX,EDI					; get row and column into EDX
	CALL GetVidMemPos			; get the position into video memory and put in EBX
	
	CMP ECX,0					; see if the digit count is 0 when we get here
	JNE .continuePrinting		; if not, go ahead and print normally
	
	MOV EAX,0					; if it is, the number we want to print will be only 0
	PUSH EAX					; push it onto the stack
	INC ECX						; add 1 to our digit counter
	
	
	.continuePrinting:			; start of printing loop
	JECXZ .return				; if ECX reaches 0, stop printing
	
	MOV EAX,0					; clear EAX
	POP EAX						; pop a digit off the stack into EAX
	ADD EAX,30h					; add 30h to the character to get the ASCII character
	
	MOV [EBX],BYTE AL			; move the character to video memory
	INC EBX						; increment vid mem position
	INC DH						; increment current column
	
	MOV EAX,ESI					; get text attribute into EAX
	MOV [EBX],AL				; text attribute
	INC EBX						; increment vid mem position
	INC DH						; increment current column
	
	DEC ECX						; decrement digit count
	JMP .continuePrinting		; jump back to print again
	
	.return:
RET


;------------------------------
; VM86 PROCEDURES
;------------------------------	

[BITS 16]


;; this code will be copied to the first mb of memory to be run as a VM86 task.
;  it runs the int 10h video interrupt.
ChangeVideoMode:

	INT 10h						; change video mode
	
	INT3						; exit VM86 mode
	
IRET
EndChangeVideoMode:				; we need this label to determine how many bytes to copy to first MB
