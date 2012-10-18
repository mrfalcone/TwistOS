;========================================================================
; diskaccess_16.asm -- 16 bit procedures regarding reading from the disk.
;
; PROCEDURES:
;-------------
;	ReadDisk -- Reads data from the disk and places it into memory.
;
;
; Updated: 02/22/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;; describe the disk address packet used in reading data from the disk
;-------------------------------
DAP:
			DB 10h				; packet size, 16 bytes
			DB 0				; reserved, must be 0
	.blk	DB 0				; temp number of blocks to read from disk
			DB 0				; reserved, must be 0
	.seg	DW 0				; temp segment of memory address at which to load data
			DW 0				; offset of memory address at which to load data
	.start	DQ 0				; starting absolute block number of data on disk
;-------------------------------
	
	
	
;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: ReadDisk -- Reads data from the disk and places it into memory. Expects
;							BX to store a 16 bit value specifying the location in memory
;							at which the data should be placed. Also expects DL to hold
;							the number of the disk drive to read. If there is an error
;							loading, AX is set to 1. If successful, AX will be 0.
ReadDisk:

	MOV [DAP.blk],AL		; put the block span in the DAP
	MOV [DAP.seg],BX		; put the memory location in the DAP
	MOV [DAP.start],CX		; put the starting block in the DAP

	
	MOV AH,42h				; bios extended read function
	MOV SI,DAP				; put the address of the DAP in SI
	INT 13h					; run the interrupt to load the kernel
	
	JNC .noError			; if there's no error, go ahead and return
	
	.error:
	MOV AX,1				; if AX isn't 0, there was an error
	JMP .return
	
	
	.noError:
	 CMP AL, BYTE [DAP.blk]	; see if we read all the sectors
	 JNE .error				; if we didn't there was an error
	 
	 MOV AX,0				; if AX is clear, there was no error
	
	.return:				; label specifying where return is
		
RET

		