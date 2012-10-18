;========================================================================
; idt_32.asm -- code handling setup of the interrupt descriptor table
;					and IRQ handlers.
;
;
;
; PROCEDURES:
;-------------
;	SetupIDT -- Sets up the entries in the IDT and then loads it into the CPU.
;
;
; ISR LIST:
;-------------
;	BlankISR -- Runs on every interrupt by default if there isn't another one defined.
;	BlankPrimaryIRQ -- Runs on every IRQ on PIC1 by default if there isn't another ISR defined.
;	BlankSlaveIRQ -- Runs on every IRQ on PIC2 by default if there isn't another ISR defined.
;	IRQ_0 -- Runs on IRQ 0: Timer.
;	IRQ_14 -- Runs on IRQ 14: ATA device from primary bus.
;	IRQ_15 -- Runs on IRQ 15: ATA device from secondary bus.
;
;
; Updated: 04/03/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================



;------------------------------
; CONSTANTS
;------------------------------
IRQ_START		EQU 20h				; this is the offset into the IDT where IRQs begin, everything before is blank
KL_IRQS			EQU 16				; number of IRQs to setup

ISR_SIZE		EQU 8				; size in bytes of the ISR descriptor


;; total number of IDT entries:
IDT_ENTRIES		EQU IRQ_START+KL_IRQS


FLAGS			EQU 010001110b		; flags for normal ISR
RESVD_FLAGS		EQU 000001110b		; flags for reserved ISR, present bit cleared
;------------------------------



;------------------------------
; BUILD TABLE
;------------------------------

;; struct for entry in the IDT
STRUC ISREntry
	.baseLow	RESW 1				; low word of ISR base
	.selector	RESW 1				; code selector
	.reserved	RESB 1				; reserved
	.flags		RESB 1				; ISR flags
	.baseHigh	RESW 1				; high word of ISR base
ENDSTRUC



;; reserve enough space for the IDT
IDTStart:
	%rep IDT_ENTRIES
		DW 0						; base low
		DW 08h						; code selector
		DB 0						; reserved
		DB FLAGS					; flags
		DW 0						; base high
	%endrep
	

;; pointer used to load the table with LIDT
IDTPointer:							; pointer used in installing the IDT
	DW (IDT_ENTRIES * ISR_SIZE) - 1	; define limit
	DD IDTStart						; define base
;------------------------------




;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: SetupIDT -- Sets up the entries in the IDT and then loads it into
;							the CPU.
SetupIDT:

	MOV EDX,IDTStart				; get the start address of the IDT into EDX

	
	;; setup the first 32 ISRs that are reserved for system use
	
	MOV EAX,BlankISR				; get the address of the blank ISR into EAX
	MOV EBX,EAX						; copy it to EBX too
	SHR EBX,16						; shift high word right so it is accessible in BX
	
	MOV ECX,0						; clear ECX, it will serve as the current entry number in the IDT
	
	.setupRsvd:						; jump here to continue setting up the reserved ISRs
	 
	 MOV [EDX+ISREntry.baseLow],AX	; put the low word of the base into entry
	 MOV [EDX+ISREntry.baseHigh],BX	; put the high word of the base into entry
	 
	 
	 ; check to see if the current entry is supposed to be reserved according to intel (ISRs 2 and 15)
	 CMP ECX,2						; see if we're on entry 2
	 JE .resvdFlags					; if it is, install reserved flags
	 CMP ECX,15						; otherwise see if we're on entry 15
	 JNE .nextEntry					; if not just go to next entry
	 
	 
	 .resvdFlags:					; jump here to install reserved flags
	 ; install reserved flags:
	 MOV [EDX+ISREntry.flags], BYTE RESVD_FLAGS
	 
	 
	 .nextEntry:					; jump here for next entry
	 ADD EDX,ISR_SIZE				; point EDX to the next entry
	 INC ECX						; increment entry number
	 
	 CMP ECX,IRQ_START				; see if we reached the end of the reserved ISRs
	 JB .setupRsvd					; if not, keep setting them up
	
	
	
	;; setup the ISRs for the 16 IRQs
	
	; setup IRQs for primary PIC:
	MOV EAX,BlankPrimaryIRQ			; get the address of the blank ISR for the primary PIC into EAX
	MOV EBX,EAX						; copy it to EBX too
	SHR EBX,16						; shift high word right so it is accessible in BX
	
	MOV ECX,0						; clear ECX to count how many IRQs have been setup
	
	.setupPrimaryIRQs:				; jump here to continue setting up the blank IRQs for primary PIC
	 
	 MOV [EDX+ISREntry.baseLow],AX	; put the low word of the base into entry
	 MOV [EDX+ISREntry.baseHigh],BX	; put the high word of the base into entry
	 
	 
	 .nextPrimary:					; jump here to go to the next IRQ entry
	 ADD EDX,ISR_SIZE				; point EDX to the next entry
	 INC ECX						; increment counter
	 
	 CMP ECX,8						; see if we have setup 8 IRQs yet
	 JB .setupPrimaryIRQs			; if not, keep setting them up
	
	
	
	; setup IRQs for slave PIC:
	MOV EAX,BlankSlaveIRQ			; get the address of the blank ISR for the slave PIC into EAX
	MOV EBX,EAX						; copy it to EBX too
	SHR EBX,16						; shift high word right so it is accessible in BX
	
	MOV ECX,0						; clear ECX to count how many IRQs have been setup
	
	.setupSlaveIRQs:				; jump here to continue setting up the blank IRQs for slave PIC
	 
	 
	 MOV [EDX+ISREntry.baseLow],AX	; put the low word of the base into entry
	 MOV [EDX+ISREntry.baseHigh],BX	; put the high word of the base into entry
	 
	 
	 .nextSlave:					; jump here to go to the next IRQ entry
	 ADD EDX,ISR_SIZE				; point EDX to the next entry
	 INC ECX						; increment counter
	 
	 CMP ECX,8						; see if we have setup 8 IRQs yet
	 JB .setupSlaveIRQs				; if not, keep setting them up
	
	
	
	;; setup IRQs used by kernel loader
	;  these need to be unmasked by the pic

	; get address of the entry for IRQ 0
	MOV EDX,((IRQ_START + 0) * ISR_SIZE) + IDTStart
	
	MOV EAX,IRQ_0					; get the address of IRQ into EAX
	MOV EBX,EAX						; copy it to EBX too
	SHR EBX,16						; shift high word right so it is accessible in BX
	MOV [EDX+ISREntry.baseLow],AX	; store low word of IRQ
	MOV [EDX+ISREntry.baseHigh],BX	; store high word of IRQ
	
	
	; get address of the entry for IRQ 14
	MOV EDX,((IRQ_START + 14) * ISR_SIZE) + IDTStart
	
	MOV EAX,IRQ_14					; get the address of IRQ into EAX
	MOV EBX,EAX						; copy it to EBX too
	SHR EBX,16						; shift high word right so it is accessible in BX
	MOV [EDX+ISREntry.baseLow],AX	; store low word of IRQ
	MOV [EDX+ISREntry.baseHigh],BX	; store high word of IRQ
	
	
	; get address of the entry for IRQ 15
	MOV EDX,((IRQ_START + 15) * ISR_SIZE) + IDTStart
	
	MOV EAX,IRQ_15					; get the address of IRQ into EAX
	MOV EBX,EAX						; copy it to EBX too
	SHR EBX,16						; shift high word right so it is accessible in BX
	MOV [EDX+ISREntry.baseLow],AX	; store low word of IRQ
	MOV [EDX+ISREntry.baseHigh],BX	; store high word of IRQ
	
	
	
	;; load the IDT
	LIDT [IDTPointer]				; load the interrupt descriptor table into the cpu
RET





;------------------------------
; INTERRUPT SERVICE ROUTINES
;------------------------------

; ISR: BlankISR -- Runs on every interrupt by default if there isn't another one defined.
;					Just prints a red ! and hangs the system.
BlankISR:

	;; panic
	
	MOV AL,'!'						; the character we will print on the screen
	
	MOV [000B8000h], BYTE AL		; move it to video memory
	MOV [000B8001h], BYTE 100b		; red text attribute
	
	.hang:							; hang the system
	JMP .hang
	
IRETD



; ISR: BlankPrimaryIRQ -- Runs on every IRQ on PIC1 by default if there isn't another ISR defined.
;							Does nothing before sending an EOI signal to the PIC.
BlankPrimaryIRQ:

	PUSH EAX						; store EAX
	
	MOV AL,20h						; put end of interrupt (EOI) into AL
	OUT PIC1,AL						; send it to the primary PIC (defined in 'picsetup_32.asm')
	
	POP EAX							; restore EAX

IRETD



; ISR: BlankSlaveIRQ -- Runs on every IRQ on PIC2 by default if there isn't another ISR defined.
;							Does nothing before sending an EOI signal to the PICs.
BlankSlaveIRQ:

	PUSH EAX						; store EAX
	
	MOV AL,20h						; put end of interrupt (EOI) into AL
	OUT PIC2,AL						; send it to the slave PIC (defined in 'picsetup_32.asm')
	OUT PIC1,AL						; send it to the primary PIC (defined in 'picsetup_32.asm')
	
	POP EAX							; restore EAX

IRETD



; ISR: IRQ_0 -- Runs on IRQ 0: Timer.
;
IRQ_0:

	PUSHAD							; push registers onto stack

	; defined in 'timer_32.asm'
	CALL ISRTimer					; call the timer ISR
	
	MOV AL,20h						; put end of interrupt (EOI) into AL
	OUT PIC1,AL						; send it to the primary PIC (defined in 'picsetup_32.asm')

	POPAD							; restore all the registers
	
IRETD



; ISR: IRQ_14 -- Runs on IRQ 14: ATA device from primary bus.
;
IRQ_14:
	CLI
	PUSHAD							; store registers
	
	
	MOV EBX,0						; specify that we are calling the ISR on the primary bus
	
	; defined in 'atapi_32.asm'
	CALL ISR_ATA					; call the ata device ISR
	
	MOV AL,20h						; put end of interrupt (EOI) into AL
	OUT PIC2,AL						; send it to the slave PIC (defined in 'picsetup_32.asm')
	OUT PIC1,AL						; send it to the primary PIC (defined in 'picsetup_32.asm')
	
	POPAD							; restore registers
	STI
IRETD


; ISR: IRQ_15 -- Runs on IRQ 15: ATA device from secondary bus.
;
IRQ_15:
	CLI
	PUSHAD							; store registers
	
	
	MOV EBX,1						; specify that we are calling the ISR on the secondary bus
	
	; defined in 'atapi_32.asm'
	CALL ISR_ATA					; call the ata device ISR
	
	MOV AL,20h						; put end of interrupt (EOI) into AL
	OUT PIC2,AL						; send it to the slave PIC (defined in 'picsetup_32.asm')
	OUT PIC1,AL						; send it to the primary PIC (defined in 'picsetup_32.asm')
	
	POPAD							; restore registers
	STI
IRETD
