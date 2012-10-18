;========================================================================
; keyboard_32.asm -- procedures for handling keypresses.
;
;
;
; PROCEDURES:
;-------------
;	KeyboardInit -- Initialize the keyboard for use.
;	PollKeyboard -- Called after a timer IRQ is received to determine the last key pressed.
;	GetLastKey   -- Returns the last key pressed in AL.
;
;
;
; Updated: 03/30/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------

MAXTESTS	EQU 500				; this is the maximum times to test whether the keyboard is ready to read

KB_ENCODER	EQU 60h				; port number of the keyboard encoder. user input is read from here.
KB_CONTROL	EQU 64h				; port number of the keyboard controller. status is read from here and
								; commands are sent

SCANCODESET	EQU 10b				; specify that we will use scan code set 1 (XT set)
;------------------------------



;------------------------------
; VARIABLES
;------------------------------
lastPressed DB	0				; this will store the scancode of the last key pressed





;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: KeyboardInit -- Initialize the keyboard for use.
;
KeyboardInit:
	

	MOV AL,0F0h						; command to set scan code set
	OUT KB_ENCODER,AL				; send to the keyboard encoder
	
	MOV AL,SCANCODESET				; get the scan code set byte
	OUT KB_ENCODER,AL				; send to the keyboard encoder

	
	
	;; enable commands
	MOV AL,0AEh						; command to enable the keyboard
	OUT KB_CONTROL,AL				; send it to the keyboard command controller
	
	
	;; clear keyboard buffer
	
	.beginReading:					; begin reading keyboard

	MOV ECX,MAXTESTS				; put the max test attempt count into ECX

	.readOutStatus:					; jump here to read keyboard out buffer status
	
	JECXZ .return					; if we used up all the status tests then just return
	DEC ECX							; decrement test count
	
	IN AL,KB_CONTROL				; read keyboard status
	TEST AL,1						; see if there is data to be read
	JZ .readOutStatus				; loop back until keyboard is ready to be read
	
	
	; once keyboard is ready to be read:
	IN AL,KB_ENCODER				; read the scancode into AL
	JMP .beginReading				; keep reading until keyboard is clear


	.return:
RET


; PROCEDURE: PollKeyboard -- Called after a timer IRQ is received to determine the last key pressed.
;
PollKeyboard:

	MOV ECX,MAXTESTS				; put the max test attempt count into ECX

	.readOutStatus:					; jump here to read keyboard out buffer status
	
	JECXZ .return					; if we used up all the status tests then just return
	DEC ECX							; decrement test count
	
	IN AL,KB_CONTROL				; read keyboard status
	TEST AL,1						; see if there is data to be read
	JZ .readOutStatus				; loop back until keyboard is ready to be read
	
	
	; once keyboard is ready to be read:
	IN AL,KB_ENCODER				; read the scancode into AL	
	
	MOV BYTE[lastPressed],AL		; store the key code as the last pressed key	
	
	JMP .readOutStatus				; loop back and keep reading until buffer is clear
	
	
	.return:
	
RET



; PROCEDURE: GetLastKey -- Returns the last key pressed in AL. Resets the last key variable.
;
GetLastKey:
	
	MOV EAX,0						; clear EAX
	
	MOV AL,BYTE[lastPressed]		; get the last key pressed
	
	MOV [lastPressed],BYTE 0		; clear the last key pressed

RET


