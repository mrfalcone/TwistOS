;========================================================================
; cputest_16.asm -- 16 bit procedures regarding testing of the cpu.
;
; PROCEDURES:
;-------------
;	TestCPU -- Tests to see if the PC has a valid processor
;
;
; Updated: 03/03/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------

BIT21 EQU 1000000000000000000000b
;------------------------------



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: TestCPU -- Tests to see if the PC has a valid processor to run
;						the OS (pentium at least). Returns AX=0 if the processor
;						is valid.
TestCPU:
	PUSHF						; push flags onto stack

	MOV EAX,0					; clear EAX
	PUSH EAX					; push it onto stack
	POPF						; read it back into eflags register
	
	PUSHF						; push the flags onto stack
	POP EAX						; pop into EAX
	
	AND EAX,BIT21				; AND to test 21st bit
	CMP EAX,BIT21				; see if bit 21 is still set
	JE .invalid					; if bit 21 is set, we could not clear it meaning we do not have a pentium
	
	
	MOV EAX,BIT21				; set bit 21 in EAX
	PUSH EAX					; put on the stack
	POPF						; pop flags with bit 21 set
	
	PUSHF						; push the flags back
	POP EAX						; and pop into EAX
	
	AND EAX,BIT21				; check to see if bit 21 is set
	JZ .invalid					; if not, cpu is invalid
	JMP .valid					; otherwise it's valid
	
	
	.invalid:					; jump here when the CPU is invalid
	MOV EAX,1					; EAX=1 means there is not a valid cpu
	JMP .return
	
	
	.valid:						; jump here when cpu is valid
	MOV EAX,0					; means that cpu is valid
	
	.return:
	POPF						; restore original flags
RET