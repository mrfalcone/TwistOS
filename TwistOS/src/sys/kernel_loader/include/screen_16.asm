;========================================================================
; screen_16.asm -- 16 bit procedures handling video display
;
; PROCEDURES:
;-------------
;	Clear16 -- Clears entire screen to black.
;	Print16 -- Prints a string to the screen.
;
;
; Updated: 03/03/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================




;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: Clear16 -- Clears entire screen to black.
;
Clear16:
	MOV CX,0					; define upper left corner of screen
	MOV DH,18h					; right-most screen position
	MOV DL,4Fh					; bottom-most screen position
	MOV AL,0					; clear entire region
	MOV AH,06h					; scroll function
	MOV BH,07h					; specify normal text attribute
	INT 10h						; run bios video interrupt
	
	MOV DX,0					; set cursor position to 0,0
	MOV BH,0					; page number 0
	MOV BL,07h					; normal text attribute
	
	MOV AH,02h					; set cursor position function
	INT 10h						; run video interrupt
RET								; return to caller


; PROCEDURE: Print16 -- Prints a string to the screen. String must end with null character.
;			  			SI must contain the address to the string.
Print16:
	MOV BH,0					; page number 0
	MOV BL,07h					; normal text attribute
	
	MOV AH,0Eh					; display teletype character function
	
	.printCh:					; label provided to print the character if the character is not 0
	 LODSB						; copies the data in SI to AL and increments SI
	 CMP AL,0					; compare the character to 0, 0 marks the end of string
	 JZ .return					; if we reached the end of the string, return from proc
	 
	 INT 10h					; run bios video interrupt
	 JMP .printCh				; jump to printCh and continue printing
	 
	.return:
RET								; return to caller


