;========================================================================
; picsetup_32.asm -- code for setting up the programmable interrupt
;						controller.
;
;
;
; PROCEDURES:
;-------------
;	PICInit -- Initializes the PIC.
;	PICWait -- Waits for a number of CPU cycles after a command word is sent to the PIC.
;
;
;
; Updated: 03/27/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================



;------------------------------
; CONSTANTS
;------------------------------
PIC1		EQU 20h					; IO base address for PIC1 (master), commands sent here
PIC2		EQU 0A0h				; IO base address for PIC2 (slave), commands sent here
PIC1_DATA	EQU PIC1+1				; data port for PIC1
PIC2_DATA	EQU PIC2+1				; data port for PIC2

WAITCYCLES	EQU 10000				; number of loop cycles to wait for the PIC to react to commands


IRQ0_OFFSET	EQU 20h					; offset of IRQ0 in interrupt table
IRQ8_OFFSET	EQU IRQ0_OFFSET + 8		; offset of IRQ8 in interrupt table


;; initialization control word:
ICW1		EQU 00010001b			; ICW1: sending 4 ICWs, 2 PICs, edge triggered, initialization bit set


;; masks
PRIMARY_MASK	EQU 11111010b		; masked interrupts on primary PIC. timer and cascade unmasked
SLAVE_MASK		EQU 00111111b		; masked interrupts on slave PIC. ata devices unmasked
;------------------------------



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: PICInit -- Initializes the PIC. Also masks unused interrupts.
;
PICInit:

	;; ICW1:
	MOV AL,ICW1						; get the first ICW into AL
	
	OUT PIC1,AL						; send it to the first PIC
	CALL PICWait					; wait for it to react to the command
	
	OUT PIC2,AL						; send it to the second PIC
	CALL PICWait					; wait for it to react to the command
	
	
	;; ICW2 (offset):
	MOV AL,IRQ0_OFFSET				; get the IRQ 0 offset into AL
	OUT PIC1_DATA,AL				; send it to the first PIC
	CALL PICWait					; wait for it to react to the command
	
	MOV AL,IRQ8_OFFSET				; get the IRQ 8 offset into AL
	OUT PIC2_DATA,AL				; send it to the second PIC
	CALL PICWait					; wait for it to react to the command

	
	;; ICW3 (specify lines for communicating between PICs):
	MOV AL,100b						; bit 2 specifies IRQ 2 to communicate with slave PIC
	OUT PIC1_DATA,AL				; send to PIC1
	CALL PICWait					; wait for it to react to the command
	
	MOV AL,10b						; bit 1 specifies that the slave is connected via IRQ 2
	OUT PIC2_DATA,AL				; send to PIC2
	CALL PICWait					; wait for it to react to the command
	
	
	;; ICW4:
	MOV AL, 1						; specify that 80x86 mode is enabled
	
	OUT PIC1_DATA,AL				; send it to PIC1
	CALL PICWait					; wait for it to react to the command
	
	OUT PIC2_DATA,AL				; send it to PIC2
	CALL PICWait					; wait for it to react to the command
	
	
	;; mask unused interrupts:
	
	MOV AL,PRIMARY_MASK				; mask interrupts 
	OUT PIC1_DATA,AL				; send it to PIC1
	CALL PICWait					; wait for it to react to the command
	
	mov AL,SLAVE_MASK				; mask interrupts 
	OUT PIC2_DATA,AL				; send it to PIC2
	CALL PICWait					; wait for it to react to the command
	

	
RET



; PROCEDURE: PICWait -- Waits for a number of CPU cycles after a command word is sent to
;						the PIC.
PICWait:
	PUSHAD							; push all the registers to the stack

	MOV ECX,WAITCYCLES				; get the number of loop cycles to wait into ECX
	
	.loop:							; jump here to keep looping
	JECXZ .done						; when ECX reaches 0, we're done
	
	DEC ECX							; decrement loop counter
	
	JMP .loop						; loop again	

	.done:							; jump here when done looping
	POPAD							; restore all the registers
RET
