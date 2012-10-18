;========================================================================
; screen_32.asm -- procedures for writing to the screen.
;
;
; PROCEDURES:
;-------------
;	PrintNumber  -- Prints a 32 bit number on the screen as ascii characters.
;	PrintString  -- Prints a string to the screen.
;	GetVidMemPos -- Calculates the current position in video memory at which
;					 to write data.
;	ClearScreen  -- Clears entire screen and resets cursor position.
;
;
; Updated: 03/02/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------
VIDEO_MEMORY	EQU 000B8000h	; start of video memory
SCREEN_COLS		EQU 80			; number of columns on the screen
SCREEN_ROWS		EQU 25			; number of rows on the screen
TEXT_ATTR		EQU 07h			; text attribute
;------------------------------




;------------------------------
; PROGRAM DATA / VARIABLES
;------------------------------
Screen:
.curRow DB 0					; byte for storing current row
.curCol DB 0					; byte for storing current column



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: PrintNumber -- Prints a 32 bit number on the screen as ascii characters. Must
;							contain the number in EAX.
PrintNumber:
	MOV EBX,0					; clear EBX
	MOV ECX,0					; clear ECX, ECX will count our digits
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
	INC BYTE [Screen.curCol]	; increment current column
	
	MOV [EBX],BYTE TEXT_ATTR	; normal text attribute
	INC EBX						; increment vid mem position
	INC BYTE [Screen.curCol]	; increment current column
	
	DEC ECX						; decrement digit count
	JMP .continuePrinting		; jump back to print again
	
	.return:
RET



; PROCEDURE: PrintString -- Prints a string to the screen. String must end with null character.
;			  				ESI must contain the address to the string. Byte 10 specifies that
;							there is a line break.
PrintString:

	CALL GetVidMemPos			; get the position into video memory and put in EBX
	
	
	.loop:						; label provided to parse special characters then print
	 LODSB						; copies the data in ESI to AL and increments ESI
	 CMP AL,0					; compare the character to 0, 0 marks the end of string
	 JZ .return					; if we reached the end of the string, return from proc
	 
	 
	 CMP AL,10					; see if this is a newline character
	 JNE .print					; if it's not, print the character
	 
	 INC BYTE [Screen.curRow]	; increase current row
	 MOV BYTE [Screen.curCol],0	; set the current column to 0
	 CALL GetVidMemPos			; recalculate the position in video memory
	 JMP .loop					; keep doing the loop
	 
	 
	
	 .print:
	  MOV [EBX],BYTE AL			; move the character to video memory
	  INC EBX					; increment vid mem position
	  INC BYTE [Screen.curCol]	; increment current column
	
	  MOV [EBX],BYTE TEXT_ATTR	; normal text attribute
	  INC EBX					; increment vid mem position
	  INC BYTE [Screen.curCol]	; increment current column

	 JMP .loop					; keep looping
	 
	.return:
RET



; PROCEDURE: ClearScreen -- Clears entire screen and resets cursor position.
;
ClearScreen:
	MOV EBX,VIDEO_MEMORY		; set EBX to start of video memory
	
	; define size of screen in ECX
	MOV ECX,SCREEN_COLS*SCREEN_ROWS
	
	
	MOV BYTE [Screen.curRow],0	; reset current row
	MOV BYTE [Screen.curCol],0	; reset current column
	
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


; PROCEDURE: GetVidMemPos -- Calculates the current position in video memory at which
;								to write data. Position is returned in EBX.
GetVidMemPos:

	MOV EAX,0					; clear EAX

	MOV EBX,0					; clear EBX
	MOV BL,[Screen.curRow]		; get the current row into EBX

	MOV EAX,SCREEN_COLS*2		; we want to multiply to get where the current row starts in video memory
								; times two because of the attribute byte
	MUL EBX						; multiply by current row
	
	
	MOV EBX,0					; clear EBX
	MOV BL,[Screen.curCol]		; get the current column into EBX
	ADD EAX,EBX					; add the current column
	
	
	MOV EBX,VIDEO_MEMORY		; put the start of video memory at EBX
	ADD EBX,EAX					; total equals the video memory at the current row and column

RET

