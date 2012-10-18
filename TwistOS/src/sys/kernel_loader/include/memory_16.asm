;========================================================================
; memory_16.asm -- 16 bit code handling memory size and the memory map.
;
; PROCEDURES:
;-------------
;	GetMemorySize -- Gets the amount of memory in the system.
;   GetMemoryMap  -- Gets the system's memory map to see what memory is available to the OS.
;
;
; Updated: 03/01/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; CONSTANTS
;------------------------------

MAP_SIZE	EQU 24				; length of memory map in bytes

;------------------------------


;------------------------------
; MEMORY MAP ENTRY STRUCTURE
;------------------------------
STRUC MemMapEntry
	.base	RESQ 1				; base address of memory range
	.length	RESQ 1				; length in bytes of memory range
	.type	RESQ 1				; type of memory
ENDSTRUC
;------------------------------




;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: GetMemorySize -- Gets the amount of memory in the system. Returns with AX=0
;								if there was no error and AX=1 if there was an error.
;								Memory amount in KB is returned in ECX.
GetMemorySize:
	MOV DX,0					; set registers to 0
	MOV CX,0					; set registers to 0
	MOV AX,0E801h				; get memory size bios function
	INT 15h						; run the interrupt
	
	JC .error					; if there was an error
	CMP AH,86h					; check to see if this was an unsupported command
	JE .error					; if it was unsupported, we have an error
	
	CMP CX,0					; if CX=0 it means that memory size was returned in
								; registers AX and BX
								
	JNE .noError				; if CX contains data then we can return with it

	MOV CX,AX					; otherwise we need to put the data in AX into CX
	MOV DX,BX					; and the data from DX into BX
	JMP .noError				; then we can return
	
	
	.error:						; label to jump to when there's an error
	MOV AX,1					; set AX to 1, 1 means error
	JMP .return					; go ahead and return
	
	
	.noError:					; label to jump to when there's no error
	
	;; CX contains number of KB between 1mb and 16mb
	;  and DX contains the number of 64kb blocks above 16mb
	
	;; actual amount of memory is: 1mb base + CX's value + (DX's value * 64kb)
	;  1024 + CX + (DX * 64) = KB of memory
	
	
	;; compute actual KB of memory in system and put it in EAX
	;  this data is already stored in variables first16 and numBlocks
	MOV EBX,0					; clear EBX
	MOV EAX,0					; clear EAX
	MOV EBX,EDX					; put number of 64k blocks in EBX
	MOV EAX, 64					; we have to multiply by 64kb
	MUL EBX						; perform the multiplication. now EAX is numBlocks*64
	ADD EAX,ECX					; add the KB in the first 16mb to the value
	ADD EAX,1024				; now add the first mb of memory to the total
	
	MOV EDX,EAX					; move the total amount of memory into EDX to return
	
	MOV EAX,0					; AX=0 means there is no error
	.return:					; return label
RET	


; PROCEDURE: GetMemoryMap -- Gets the system's memory map to see what memory is available to the OS.
;								DI must point to the address where the first entry is placed.
GetMemoryMap:
	MOV EBX,0					; continuation value, must be 0 to start
	MOV BP,0					; clear BP, this will contain our number of entries
	
	MOV EDX,'PAMS'				; put value 'SMAP' into EDX, put in backwards because intel is little endian
	MOV EAX,0E820h				; get memory map bios function
	MOV ECX,MAP_SIZE			; define memory map entry size

	INT 15h						; run the bios interrupt
	
	JC .error					; if carry flag is not 0 there was an error
	CMP EAX,'PAMS'				; see if EAX returned the signature correctly
	JNE .error					; if not, there's an error
	CMP EBX,0					; if EBX is 0 that means that there are no more entries
	JE .error					; so we have an error
	JMP .checkEntry				; check the first entry and get started
	
	
	.getEntry:					; get the next entry
	MOV EDX,'PAMS'				; set interrupt signature
	MOV ECX,MAP_SIZE			; define memory map entry size
	MOV EAX,0E820h				; get memory map bios function
	INT 15h						; run the bios interrupt
	
	
	.checkEntry:				; checks the entry to see if it's good
	JCXZ .moveOn				; if CX is 0 that means nothing was returned by the interrupt
	
	; get low dword of length
	MOV ECX,[ES:DI+MemMapEntry.length]
	CMP ECX,0					; see if length is 0
	JNE .useEntry				; if it isn't, use it
	; get high dword of length
	MOV ECX,[ES:DI+MemMapEntry.length+4]
	JECXZ .moveOn				; if length is 0, move on
	
	
	; use the entry if it's good
	.useEntry:					; use the entry
	INC BP						; increment our entry count
	ADD DI,MAP_SIZE				; add map size to DI to point it to the next entry pos
	
	.moveOn:					; move past current entry
	CMP EBX,0					; see if there are any more entries
	JE .done					; if there aren't, we're done
	JMP .getEntry				; otherwise get the next entry
	
	
	.error:						; jump here if there's an error
	MOV EAX,1					; set EAX to 1 to mean that there's an error
	JMP .return					; return with error code
	
	.done:						; jump here when done
	MOV EAX,0					; set EAX to 0 before returning
	
	.return:					; label for returning from the procedure
RET
