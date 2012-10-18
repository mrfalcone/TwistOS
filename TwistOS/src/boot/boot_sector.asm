;========================================================================
; boot_sector.asm -- assembles to a 512-byte boot sector from which the x86 PC
;					is booted. This is the first stage in booting the OS.
;
;
; Steps performed by this boot sector:
; -------------------------------
;  first, see if user presses a key, if not, don't even continue
;  1. test to see if user has valid processor. it must be at least a pentium
;     and is determined in 'cputest_16.asm'.
;  2. next, load the kernel loader into memory.
;  3. jump to location of kernel loader in memory. the kernel loader will set
;		up additional things needed for the kernel to run and it will actually
;		load the kernel and boot it.
;
; If at any point the boot process cannot continue, an error message
; is displayed and the system hangs.
;
;
; -- Assembled with NASM 2.06rc2 --
; Updated: 03/03/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------

KLPOS		EQU 0D000h			; location at which to load kernel loader in memory
KLBLOCKSPAN	EQU 4				; number of blocks the kernel loader takes up on disk
KLBLOCK		EQU 23				; the kernel loader's residing block on the disk


KEYWAIT		EQU 15				; number of seconds to wait for the user to press a key

;------------------------------




;------------------------------
; BOOTSECTOR ENTRY
;------------------------------

[BITS 16]						; generate 16-bit code
[ORG 7C00h]						; memory location from which to begin execution


CLI								; disable interrupts


;; setup segment registers
MOV AX,0						; set AX to 0
MOV DS,AX						; set data segment
MOV ES,AX						; set extra segment
MOV SS,AX						; set stack segment
MOV SP,800h						; set stack pointer

STI								; re-enable interrupts


PUSH DX							; push DX onto stack; DL contains drive number of disk


JMP 0h:Begin					; jump to the start of the boot operation



;------------------------------
; INCLUDED FILES
;------------------------------

; this file contains procedures dealing with display and prints strings
%include "include/screen_16.asm"
;this file handles checking for errors
%include "include/error_16.asm"
; this file handles reading the disk:
%include "include/diskaccess_16.asm"
; this file checks to see if the cpu is valid
%include "include/cputest_16.asm"


;------------------------------
; PROGRAM DATA / STRINGS
;------------------------------

strPressKey		DB "Press any key to boot CD.",0


; error strings:
errCPU			DB "Processor not supported!",0
errDisk			DB "Error reading disk!",0


;------------------------------
; BEGIN BOOT OPERATION
;------------------------------

Begin:
	
	CALL Clear16				; clear the screen
	
	CALL TestCPU				; test the CPU
	
	MOV SI,errCPU				; get CPU error string
	CALL CheckError				; check for errors

	
;------------------------------
; ASK FOR KEY
;------------------------------
	
	
	;; ask user to press a key to continue booting
	MOV SI,strPressKey			; put string location in SI
	CALL Print16				; run the proc to print the string to the screen


	CALL WaitForKey				; wait for the keypress

	
	CMP AX,0					; if AX=0, a key was pressed
	JNE Reboot					; if key wasn't pressed, reboot


;------------------------------
; READ KERNEL LOADER INTO MEMORY
;------------------------------

	CALL Clear16				; clear the screen
	
	
	POP DX						; get the drive number off the stack
	
	MOV AX,0					; clear AX
	MOV AL,KLBLOCKSPAN			; specify block span of the kernel
	
	MOV BX,KLPOS				; specify the position where the kernel loader goes
	MOV CX,KLBLOCK				; specify the starting block of the kernel loader
	
	
	;; defined in 'diskaccess_16.asm':
	CALL ReadDisk				; read the disk and put the data in memory location specified by BX
	
	MOV SI,errDisk				; get the disk error string
	CALL CheckError				; check to see if there was an error

	
	; determine the start of the kernel loader code

	MOV BX,WORD [KLPOS]			; get the low word of the size of the EBC header
	MOV AX,KLPOS				; get the start of the kernel loader file in memory
	ADD AX,BX					; add the size of the header to it
	
	
	JMP AX						; jump to memory location where kernel loader code starts

	
	; *** at this point we should be done with this code ***
	
	
	Hang:						; hang the system
		JMP Hang
	
;------------------------------------------------------------------------------
;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: WaitForKey -- waits KEYWAIT seconds for key to be pressed and 
;							outputs a dot every second. Returns with AX=0 if
;							key was pressed. AX=1 if key was not pressed.
WaitForKey:

	MOV CX,KEYWAIT				; put the wait for key counter into CX

	.start:
	MOV AH,1					; specifies that INT 16h checks for keypress, but does not wait
	INT 16h						; test if a key has been pressed
	JNZ .pressed				; key was pressed
	
	;; wait for a little bit before moving on
	PUSH CX						; store CX before we continue
	MOV CX,0Fh					; high word of wait interval
	MOV DX,4100h				; low word of wait interval
	MOV AH,86h					; specifies that INT 15h uses the wait function
	INT 15h						; wait for a second
	POP CX						; restore CX
	
	;; keep displaying a dot to show that we are doing something
	MOV AH,0Eh					; display teletype character function
	MOV AL,'.'					; display a dot
	INT 10h						; run bios video interrupt
	
	DEC CX						; decrement the wait counter
	JNZ .start					; loop back to wait for the key again
	
	.notPressed:				; if key wasn't pressed
	MOV AX,1					; if we return with AX as 1, no key was pressed
	JMP .return					; return
	
	.pressed:					; go here if key was pressed
	MOV AX,0					; set AX to 0 if key was pressed
	
	.return:
RET


; PROCEDURE: Reboot -- Reboots the PC.
;		
Reboot:
	DB 0EAh						; reboot computer
	DW 0
	DW 0FFFFh
JMP Reboot						; just keep looping until we actually reboot
	
;------------------------------------------------------------------------------



;------------------------------
; BOOT SECTOR ENDING
;------------------------------

TIMES 510-($-$$) DB 0			; fill with 0s until file is 510 bytes
DW 0AA55h						; mark end of boot sector with these two bytes
