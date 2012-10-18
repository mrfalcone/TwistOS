;========================================================================
; menu_32.asm -- displays a menu with options for booting the kernel
;
;
;
; PROCEDURES:
;-------------
;	ExecuteMenu -- Executes the menu and returns with the menu selection in EAX.
;	PrintSelection -- Print the menu selection item.
;	PrintDescription -- Print the description of the selected menu item.
;
;
; Updated: 03/29/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================



;------------------------------
; CONSTANTS
;------------------------------

KEY_UP_MAKE		EQU 48h				; up key make code
KEY_DOWN_MAKE	EQU 50h				; down key make code
KEY_ENTER_MAKE	EQU 1Ch				; enter key make code


;; currently not used:
KEY_UP_BREAK	EQU 0C8h			; up key break code
KEY_DOWN_BREAK	EQU 0D0h			; down key break code
KEY_ENTER_BREAK	EQU 9Ch				; enter key break code
;------------------------------



;------------------------------
; VARIABLES / STRINGS
;------------------------------

selection		DB 0				; this stores the selected menu item 0-2


;; menu strings:

strMenuHeader	DB " Twist OS Boot Menu",10,
				DB "様様様様様様様様様様",10,10,0


strSelected		DB " 陳> ",0
strUnselected	DB "     ",0


;; menu selections
strBootNormal	DB "Boot normally",10,0
strBootText		DB "Boot in text mode",10,0
strBootGui		DB "Boot in graphical mode",10,0



strDescription	DB 10,10,10,10,10," Description:",10,0

;; selection descriptions
strNormalDesc	DB "   Boots the operating system according to the default boot mode.",0
strTextDesc		DB "   Boots the operating system in text mode.",0
strGuiDesc		DB "   Boots the operating system in graphical mode.",0





;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: ExecuteMenu -- Executes the menu and returns with the menu selection in EAX.
;
ExecuteMenu:
	
	CALL DrawMenu					; draw the menu on the screen
	
	
	.waitForKey:					; wait for a keypress to happen
	 
	 CALL GetLastKey				; get the last key pressed into AL
	 
	 
	 CMP AL,KEY_UP_MAKE				; see if it's the up key
	 JE .upArrow					; handle it
	 
	 
	 CMP AL,KEY_DOWN_MAKE			; see if it's the down key
	 JE .downArrow					; handle it
	 
	 
	 CMP AL,KEY_ENTER_MAKE			; see if it's the enter key
	 JE .enterPressed				; handle it
	 
	 
	JMP .waitForKey					; keep waiting for a key
	
	
	.downArrow:						; jump here when down arrow is pressed
	MOV AL,BYTE [selection]			; get selection number into AL
	
	
	CMP AL,2						; see if it's at the max position
	JE .waitForKey					; if it is, keep waiting for a key
	
	
	INC AL							; otherwise increment selection number
	MOV BYTE [selection],AL			; and store it
	
	CALL DrawMenu					; redraw the menu
	
	JMP .waitForKey					; keep waiting for a key
	
	
	
	.upArrow:						; jump here when up arrow is pressed
	MOV AL,BYTE [selection]			; get selection number into AL
	
	
	CMP AL,0						; see if it's at the min position
	JE .waitForKey					; if it is, keep waiting for a key
	
	
	DEC AL							; otherwise decrement selection number
	MOV BYTE [selection],AL			; and store it
	
	CALL DrawMenu					; redraw the menu
	
	JMP .waitForKey					; keep waiting for a key
	
	
	
	.enterPressed:					; jump here when enter is pressed
	
	CALL ClearScreen				; clear the screen

	MOV EAX,0						; clear EAX
	MOV AL,BYTE[selection]			; get the selection number
	
RET



; PROCEDURE: DrawMenu -- Draws the menu on screen.
;
DrawMenu:

	CALL ClearScreen				; clear the screen
	
	MOV ESI,strMenuHeader			; get string
	CALL PrintString				; print the menu header
	
	
	;; draw menu selections:
	
	MOV ESI,strBootNormal			; get first selection
	MOV EAX,0						; put selection number in EAX
	CALL PrintSelection				; print the selection
	
	MOV ESI,strBootText				; get second selection
	MOV EAX,1						; put selection number in EAX
	CALL PrintSelection				; print the selection
	
	MOV ESI,strBootGui				; get third selection
	MOV EAX,2						; put selection number in EAX
	CALL PrintSelection				; print the selection
	
	
	MOV ESI,strDescription			; get description string
	CALL PrintString				; print it
	
	
	CALL PrintDescription			; now print the description

RET


; PROCEDURE: PrintSelection -- Print the menu selection item. ESI should be the selection string
;								and EAX is the number of the selection.
PrintSelection:
	PUSH ESI						; store selection string on stack
	
	MOV ESI,strUnselected			; get the unselected indicator, if the menu item is selected this changes
	
	
	CMP BYTE[selection],AL			; see if the current menu selection is selected
	JNE .printSelection				; if it's not, print the selection
	
	MOV ESI,strSelected				; if it is, change the indicator to selected
	

	.printSelection:				; jump here to print the selection
	
	CALL PrintString				; print the selection indicator first
	
	POP ESI							; get the selection string off the stack
	CALL PrintString				; and then print it

RET


; PROCEDURE: PrintDescription -- Print the description of the selected menu item.
;
PrintDescription:

	MOV EAX,0						; clear EAX
	
	MOV AL,BYTE[selection]			; get the selected item into AL
	
	
	CMP AL,0						; see if first item is selected
	JE .first						; if it is, print the description
	
	CMP AL,1						; see if second item is selected
	JE .second						; if it is, print the description
	
	CMP AL,2						; see if third item is selected
	JE .third						; if it is, print the description

	JMP .return						; this should not be reached
	

	.first:							; print the first description
	MOV ESI,strNormalDesc			; get description string
	CALL PrintString				; print it
	JMP .return			 			; and return
	
	.second:						; print the second description
	MOV ESI,strTextDesc				; get description string
	CALL PrintString				; print it
	JMP .return			 			; and return
	
	.third:							; print the third description
	MOV ESI,strGuiDesc				; get description string
	CALL PrintString				; print it


	.return:						; jump here to return from printing
RET

