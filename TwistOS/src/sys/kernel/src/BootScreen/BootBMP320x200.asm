;========================================================================
; BootBMP320x200.asm 
; ----------------------------------
; Implementation of the BootBMP320x200 class. Includes a bmp file and
; and arranges the pixels to be copied to video memory in VGA video mode
; 0x12 (320x200 with 16 colors).
;
; C++ header: BootBMP320x200.h
;
;
; -- Assembled with NASM 2.06rc2 --
; Author   : Mike Falcone
; Email    : mr.falcone@gmail.com
; Modified : 05/18/2009
;========================================================================

[BITS 32]


;------------------------------
; GLOBALS
;------------------------------
;; functions declared in "BootBMP320x200.h"
[GLOBAL _ZN14BootBMP320x200C2Ev]
[GLOBAL _ZN14BootBMP320x200C1Ev]
[GLOBAL _ZN14BootBMP320x20014UpdateProgressEv]
[GLOBAL _ZN14BootBMP320x20015GetScreenBufferEv]
;------------------------------


;------------------------------
; DIB HEADER STRUCTURE
;------------------------------
STRUC DIB
	.headerSize		RESD 1
	.bmpWidth		RESD 1
	.bmpHeight		RESD 1
	.colorPlanes	RESW 1
	.bpp			RESW 1
	.compression	RESD 1
	.imageSize		RESD 1
	.hRes			RESD 1
	.vRes			RESD 1
	.palColors		RESD 1
	.impColors		RESD 1
ENDSTRUC
;------------------------------


;------------------------------
; CONSTANTS
;------------------------------
SCREEN_WIDTH	EQU 320			; width of the screen in pixels
SCREEN_HEIGHT	EQU 200			; height of the screen in pixels
VIDEO_SIZE		EQU SCREEN_WIDTH*SCREEN_HEIGHT

PALETTE_SIZE	EQU 216*4		; size of the bitmap palette in bytes
;------------------------------



;------------------------------
; DATA
;------------------------------
[SECTION .data]

BMPBytes:
incbin "twistboot.bmp"			; include the bytes of the boot screen bitmap


VidMemBuffer:
%rep VIDEO_SIZE
	DB 0						; reserve byte for each byte in video memory
%endrep




;------------------------------
; GLOBAL C++ FUNCTIONS
;------------------------------
[SECTION .text]

;; BootBMP320x200()
_ZN14BootBMP320x200C2Ev:
_ZN14BootBMP320x200C1Ev:

	
	PUSHAD
	
	CALL LoadBuffer					; load the video buffer with the bitmap data
	
	POPAD
RET


;; void UpdateProgress()
_ZN14BootBMP320x20014UpdateProgressEv:
	
RET



;; const char* GetScreenBuffer()
_ZN14BootBMP320x20015GetScreenBufferEv:
	
	MOV EAX,VidMemBuffer			; get the address of the start of the video memory buffer
									; to return in EAX
RET



;------------------------------
; LOCAL PROCEDURES
;------------------------------

; PROCEDURE: LoadBuffer -- Reads the bitmap file and loads the screen buffer.
;
LoadBuffer:

	
	;; set EDX as a pointer to our DIB header
	MOV EDX,BMPBytes				; get a pointer to the bitmap file's bytes
	ADD EDX,0Eh						; the DIB header starts at 0xE
	
	
	
	;; set ESI as a pointer to the image data
	MOV ESI,EDX						; get a pointer to the DIB header
	MOV EAX,[EDX+DIB.headerSize]	; adding the header size gets a pointer to the palette
	ADD ESI,EAX
	ADD ESI,PALETTE_SIZE			; skip past the palette data to get the image data
	
	
	MOV ECX,[EDX+DIB.bmpWidth]		; get pixels-per-row into ECX
	
	
	MOV EBX,[EDX+DIB.bmpHeight]		; get number of rows into EBX
	
	
	.drawRows:						; this loop will draw each row of the bitmap
		
		CALL DrawRow				; draw the current row
		
		DEC EBX						; decrement row
		CMP EBX,0					; see if we're done with row 0 yet
	JA .drawRows					; if not loop back to draw more rows
	

RET



; PROCEDURE: DrawRow -- draws the current row in the bitmap onto the video buffer.
;						EBX must contain the row on screen. ECX must contain the
;						number of bytes in the row. ESI must point to beginning
;						of the row in the bitmap.
DrawRow:
	

	PUSHAD
	
	;; find byte offset of row start in video memory
	MOV EAX,SCREEN_WIDTH		; get width of the screen in pixels
	MUL EBX						; multiply by the row number
	
	
	MOV EDI,VidMemBuffer		; get start of buffer
	ADD EDI,EAX					; add byte offset, now EDI points to location in video memory to write
	
	REP MOVSB					; copy the entire row to video memory
	
	
	POPAD
	
	ADD ESI,ECX					; add the number of bytes per row
	
	
RET


