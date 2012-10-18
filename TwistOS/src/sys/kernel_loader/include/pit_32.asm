;========================================================================
; pit_32.asm -- code for setting up the programmable interval timer.
;
;
;
; PROCEDURES:
;-------------
;	PITInit -- Initializes counter 0 in the PIT.
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
PIT_HZ			EQU (3579545 / 3)	; frequency of the PIT, about 1193182 hz

TIMER_FREQ		EQU 100				; frequency of timer in hertz (100 = 10 milliseconds)

COUNTER_VAL		EQU PIT_HZ / TIMER_FREQ


CONTROL_WORD0	EQU 00110110b		; control word to use for accessing counter 0


REG_CONTROL		EQU 43h				; port of control register
REG_COUNTER0	EQU 40h				; port of counter 0, the counter we want to use
;------------------------------




;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: PITInit -- Initializes counter 0 in the PIT.
;
PITInit:

	MOV EAX,0						; clear EAX
	MOV EBX,0						; clear EBX
	MOV EDX,0						; clear EDX
	
	MOV DX,COUNTER_VAL				; value to be sent to counter register (16 bit register)
	
		
	
	MOV AL,CONTROL_WORD0			; put control word into AL so we can send it to the PIT
	OUT REG_CONTROL,AL				; send it to the PIT
	
	;; the control word should specify that we are sending the least significant byte of the
	;  counter register first, so we're doing that
	
	MOV AX,DX						; get the value of the counter register into AX
	
	OUT REG_COUNTER0, AL			; send the low byte of the counter register
	
	MOV AL,AH						; move high byte to AL
	
	OUT REG_COUNTER0, AL			; send the high byte of the counter register

RET

