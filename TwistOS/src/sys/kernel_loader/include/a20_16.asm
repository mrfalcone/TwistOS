;========================================================================
; a20_16.asm -- 16 bit procedures regarding the A20 gate.
;
; PROCEDURES:
;-------------
;	A20Enable -- Attempts to enable the A20 gate.
;	WaitForWrite -- Waits for the input buffer to be clear.
;	WaitForRead -- Waits for the output buffer to be set.
;	TestGate -- Test whether or not the A20 gate is enabled.
;
;
; Updated: 05/07/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------
A20_RETRY	EQU 1000			; number of times to try enabling the A20 gate

A20_ENCODER	EQU 60h				; port number of the keyboard encoder
A20_CONTROL	EQU 64h				; port number of the keyboard controller
;------------------------------


;------------------------------
; PROCEDURES
;------------------------------


; PROCEDURE: A20Enable -- Attempts to enable the A20 gate 'A20_RETRY' times.
;							if it cannot be enabled, AX is set to 1. If it is
;							successfully enabled, AX is set to 0.
A20Enable:
	
	CALL TestGate				; test the A20 gate
	CMP AX,1					; see if gate is enabled
	JE .noError					; if so, there's no need to do the rest
	
	
	MOV CX,A20_RETRY			; set retry counter
	
	
	.start:						; begin trying to enable the gate
	JCXZ .error					; if counter has reached 0, we used up all tries and there's an error
	DEC CX						; decrement counter
	
	MOV AX,0					; clear AX
	
	;; read the output port data and store on stack
	CALL WaitForWrite			; wait for input buffer to be clear
	
	MOV AL,0D0h					; load AL with command byte to read output port
	OUT A20_CONTROL,AL			; send it to kb controller
	CALL WaitForRead			; wait for output buffer to be full
	
	IN AL,A20_ENCODER			; read data from the output port
	PUSH AX						; store the data on stack
	
	
	;; write byte to enable a20 gate
	CALL WaitForWrite			; wait for input buffer to be clear
	
	MOV AL, 0D1h				; load AL with command byte to write output port
	OUT A20_CONTROL,AL			; send it to kb controller
	CALL WaitForWrite			; wait for input buffer to be clear
	
	
	POP AX						; get output port data off stack
	OR AL,10b					; set bit 1 to enable the a20 gate
	OUT A20_ENCODER,AL			; send byte to the keyboard encoder
	
	
	CALL TestGate				; test the A20 gate
	CMP AX,1					; see if gate is enabled
	JE .noError					; if so, there is no error
	
	JMP .start					; otherwise, go back to try again
	
	
	.error:
	MOV AX,1					; if AX isn't 0, there was an error
	JMP .return
	
	
	.noError:
	CALL WaitForWrite			; wait for input buffer to be clear
	MOV AX,0					; if AX is clear, there was no error
	
	
	.return:
RET



; PROCEDURE: WaitForWrite -- Waits for the input buffer to be clear.
;
WaitForWrite:
	
	PUSH CX						; store current counter on stack
	
	MOV CX,A20_RETRY			; set retry counter
	
	.read:						; begin reading
	JCXZ .return				; when CX gets down to zero, return
	DEC CX						; decrement counter
	
	IN AL,A20_CONTROL			; read kb controller status
	TEST AL,10b					; test bit 1
	
	JNZ .read					; if bit 1 is set, keep checking status to wait for it to be clear
	
	.return:
	POP CX						; restore old counter
RET


; PROCEDURE: WaitForRead -- Waits for the output buffer to be set.
;
WaitForRead:
	
	PUSH CX						; store current counter on stack
	
	MOV CX,A20_RETRY			; set retry counter
	
	.read:						; begin reading
	JCXZ .return				; when CX gets down to zero, return
	DEC CX						; decrement counter
	
	IN AL,A20_CONTROL			; read kb controller status
	TEST AL,10b					; test bit 0
	
	JZ .read					; if bit 0 is clear, keep checking status to wait for it to be set
	
	.return:
	POP CX						; restore old counter
RET


; PROCEDURE: TestGate -- Test whether or not the A20 gate is enabled. Returns AX=1
;							if enabled, AX=0 otherwise.
TestGate:
	
	PUSH FS						; store FS on stack
	PUSH ES						; store ES on stack
	
	
	MOV AX,0					; set AX to zero to set ES
	MOV ES,AX					; set ES to 0
	
	MOV AX,0FFFFh				; set AX to set FS
	MOV FS,AX					; set FS to FFFFh
	
	
	MOV DI,500h					; set DI
	MOV SI,510h					; set SI
	
	
	MOV BYTE [ES:DI],0			; set byte at [ES:DI] to 0
	MOV BYTE [FS:SI],0FFh		; set byte at [FS:SI] to 0xFF
	
	CMP BYTE [ES:DI],0FFh		; if A20 is not enabled and memory wraps, this byte will be equal
	JNE .enabled				; if it's not equal, the A20 gate is enabled
	
	
	.disabled:
	MOV AX,0					; 0 means not enabled
	JMP .return					; return
	
	.enabled:
	
	;; test to see if A20 bit is set
	CALL WaitForWrite			; wait for input buffer to be clear
	
	MOV AL,0D0h					; load AL with command byte to read output port
	OUT A20_CONTROL,AL			; send it to kb controller
	CALL WaitForRead			; wait for output buffer to be full
	
	IN AL,A20_ENCODER			; read data from the output port
	TEST AL,10b					; test bit 1 for a20 gate
	JZ .disabled				; if not set, go to disabled label
	
	MOV AX,1					; 1 means enabled
	
	
	.return:
	POP ES						; restore ES
	POP FS						; restore FS
RET


