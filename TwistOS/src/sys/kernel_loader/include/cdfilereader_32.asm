;========================================================================
; cdfilereader_32.asm -- procedures for reading CDs with the ISO 9660
;							filesystem.
;
;
; PROCEDURES:
;-------------
;	MountDisk -- Mounts the CD so that it can be read.
;	ReadPrimaryVolDescriptor -- Reads the Primary Volume Descriptor to get the size and location of the path table.
;	ReadPathTable -- Reads the path table to get the block number of the dir specified by the string starting at ESI.
;	CheckPathRecord -- Checks the record found in the path table to see if it matches the directory specified by ESI.
;	ReadPath -- Reads the path to search for the file specified by ESI.
;	ReadFileInfoFromDisk -- Reads the disk to find the block number and size of the file specified by ESI.
;	ReadFileToMem -- Reads the file from the disk into memory.
;
;
;
; Updated: 04/12/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================



;------------------------------
; INCLUDES
;------------------------------
;; this file contains code for reading files and file info from the cd using ATAPI
%include "include/atapi_32.asm"




;------------------------------
; CONSTANTS
;------------------------------
PRIMARY_VOL_DESC	EQU 16			; block number of the primary volume descriptor to read from disk
READ_LOC			EQU 0800000h	; location at which to read data from disk, about 8mb location
;------------------------------




;------------------------------
; PROGRAM DATA / STRINGS
;------------------------------
systemDirName	DB "System"			; name of the system directory
systemDirBlock	DD 0				; this will store the block number of the system directory


driverDirName	DB "drivers"		; name of the kernel drivers directory
driverDirBlock	DD 0				; this will store the block number of the drivers directory


;; strings:
strMounted	DB " ¯ Disk mounted.",10,0

errMount	DB " ¯ !!!! Error: could not mount disk!",10,0

errFind1	DB " ¯ !!!! Error: could not read file: ",0
errFind2	DB "!",10,0

errReadFile	DB " ¯ !!!! Error: unable to read file from CD!",10,0



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: MountDisk -- Mounts the CD so that it can be read. Hangs system on error.
;
MountDisk:

	CALL ATAInit					; initialize ATA device
	

	
	;; read primary volume descriptor:
	;-------------------------------
	MOV EAX,READ_LOC				; get the read location
	MOV EBX,PRIMARY_VOL_DESC		; get the primary volume descriptor block number
	CALL ReadOneSector				; read the sector
	
	
	CMP BYTE[READ_LOC],1			; make sure this is the primary volume descriptor
	JNE .error						; if not, there's an error
	
	
	CALL ReadPrimaryVolDescriptor	; read the primary volume descriptor for size and block of path table
	
	CMP EAX,0						; see if size is 0
	JE .error						; if so, there's an error
	
	PUSH EAX						; store size on the stack
	
	CMP EBX,0						; see if block number is 0
	JE .error						; if so, there's an error
	;-------------------------------
	
	
	;; read path table:
	;-------------------------------
	MOV EAX,READ_LOC				; get the read location
	; EBX is already set to block number
	CALL ReadOneSector				; read the sector
	

	; read the path table to get the block number of system folder
	MOV ECX,[ESP]					; get the path table size from the stack, but keep it there
	
	MOV ESI,systemDirName			; get the name of the system directory to find it
	CALL ReadPathTable				; read the path table for it
	
	CMP EAX,0						; see if block number is set to 0
	JE .error						; if it, there's an error
	
	MOV [systemDirBlock],EAX		; store block number
	

	
	; read the path table to get the block number of driver folder
	POP ECX							; get the path table size from the stack
	
	MOV ESI,driverDirName			; get the name of the driver directory to find it
	CALL ReadPathTable				; read the path table for it
	
	CMP EAX,0						; see if block number is set to 0
	JE .error						; if it, there's an error
	
	MOV [driverDirBlock],EAX		; store block number
	;-------------------------------
	

	JMP .return						; return now
	
	
	
	.error:							; jump here when there's an error
	MOV ESI,errMount				; get error string
	CALL PrintString				; print it
	
	.hang:
	JMP .hang						; hang the system on error
	
	
	.return:
	MOV ESI,strMounted				; get mounted string
	CALL PrintString				; print it
RET



; PROCEDURE: ReadPrimaryVolDescriptor -- Reads the Primary Volume Descriptor to get the size and
;											location of the path table. Returns size in EAX and block in EBX.
ReadPrimaryVolDescriptor:

	.pathTableSizeOffset	EQU 132
	.pathTableBlockOffset	EQU 140

	
	MOV EAX,0					; clear EAX
	
	; get size of the path table in EAX
	MOV EAX, DWORD[READ_LOC+.pathTableSizeOffset]
	

	MOV EBX,0					; clear EBX
	
	; get the path table block
	MOV BL, BYTE[READ_LOC+.pathTableBlockOffset]

RET



; PROCEDURE: ReadPathTable -- Reads the path table to get the block number of the dir specified
;								by the string starting at ESI. ECX must be size of the path table.
;								Returns EAX=block number if found. If not found, returns EAX=0.
ReadPathTable:

	.entryBaseSize	EQU 8		; base size of an entry in bytes
	
	
	PUSH ESI					; store address of folder name to find on stack
	
	
	MOV EDX,READ_LOC			; get the beginning of the location where the path table was read in
	
	ADD ECX,EDX					; add the path table size to beginning of read location
								; we won't read past this number of bytes
	
	
	ADD EDX,.entryBaseSize		; add the base size of the entry to EDX
	ADD EDX,2					; add the offset for path id, it is 2 for root
	
	
	.readRecord:
	
	MOV EBX,0					; clear EBX
	
	
	CMP EDX,ECX					; compare end of the path table to the current read location
	JAE .doneReading			; if read location is past the end of the path table, we're done reading
	
	MOV BL, BYTE[EDX]			; get the byte at EDX, it stores size of the next path id
	
	MOV EAX,0					; clear EAX
	MOV AL, BYTE[EDX+2]			; the byte at EDX+2 is the block number of the current record
	
	ADD EDX, .entryBaseSize		; add the base size of the entry to EDX
	
	
	MOV ESI,[ESP]				; get ESI from the stack but keep it there
	
	
	CALL CheckPathRecord		; check the current record
	
	
	CMP EAX,0					; if EAX=0 the record was not a match
	JE .readRecord				; so go read the next record
	

	.doneReading:				; jump here when done reading records
	POP ESI						; be sure to get ESI off the stack
RET



; PROCEDURE: CheckPathRecord -- Checks the record found in the path table to see if it matches the directory
;							specified by ESI. EBX is the length of the dir ID. EDX is the beginning of the
;							id to test. EAX is the block number of the current record. Returns EAX unchanged
;							if there is a match, and EAX=0 if there is not a match. Returns with EDX at the
;							beginning of the next record.
CheckPathRecord:

	PUSH EDX					; store EDX on stack
	PUSH ECX					; store ECX on stack
	PUSH EBX					; store EBX on stack
	PUSH EAX					; store EAX on stack
	
	MOV ECX,0					; clear ECX
	MOV ECX,EBX					; put the character count into ECX
	MOV EBX,0					; clear EBX
	
	MOV EAX,0					; clear EAX

	
	.check:						; begin checking
	JECXZ .match				; if we made it far enough for ECX to be 0, we have a match

	LODSB						; copies the data in SI to AL and increments SI
	MOV BL, BYTE[EDX]			; get the character at EDX
	INC EDX						; increment EDX to get next character in record
	
	CMP AL,BL					; compare the characters
	JNE .noMatch				; if they aren't equal, there is not a match

	DEC ECX						; otherwise decrement the character count
	JMP .check					; and check the next character	
	
	
	.noMatch:					; jump here if there is not a match
	POP EAX						; get EAX off the stack, it is the block number of the current record
	MOV EAX,0					; clear it to mean no match
	JMP .return					; return
	
	.match:						; jump here if there is a match
	POP EAX						; get AX off the stack, it is the block number of the current record

	.return:					; jump here to return
	POP EBX						; restore BX
	
	POP ECX						; restore ECX
	POP EDX						; restore EDX
	
	TEST BL,1					; see if bit 0 of BL is set, if it is, the character count is odd
	JZ .add						; if it's even, go ahead and add the number
	
	INC EBX						; otherwise we have to increment the number so it will be even
	
	.add:						; jump here to add to EDX
	ADD EDX,EBX					; add the character count to EDX so we return at start of next record
	
RET



; PROCEDURE: ReadPath -- Reads the path to search for the file specified by ESI. If found, returns EAX=block
;							number and ECX=filesize. If not, EAX and ECX will be 0.
ReadPath:

	.startBlockOffset	EQU 2
	.fileSizeOffset		EQU 10
	.idLengthOffset		EQU	32
	
	PUSH ESI					; push filename address onto the stack
	
	JMP .start					; go to the start of the procedure
	
	
	.startBlock	DD 0			; this will hold the starting block of the file
	.fileSize	DD 0			; this will store the size of the file
	.readLoc	DD 0			; this will store the read location
	
	.start:						; jump here to begin
	
	MOV EDX,READ_LOC			; get the beginning of the read location
	MOV [.readLoc],EDX			; store it for use in loop
	
	MOV ECX,0					; clear ECX
	MOV EBX,0					; clear EBX
	

	.readEntry:					; read the entry
	
	MOV ECX,0					; clear ECX
	MOV EDX,[.readLoc]			; get location of start of entry
	MOV CL, BYTE [EDX]			; get the first byte, it is the length of the current entry
	JECXZ .noMatch				; when ECX is 0 stop reading because it means the next entry length is nothing
	
	
	MOV EBX,EDX					; put entry start address into EBX so we can add the byte count
	ADD EBX,ECX					; add the byte count to get the start of next entry
	MOV [.readLoc],EBX			; store it for next iteration of loop


	
	; get the block number of the start of the file
	MOV EAX, DWORD [EDX+.startBlockOffset]
	MOV [.startBlock],EAX		; store it
	
	; get the size of the file
	MOV EAX, DWORD [EDX+.fileSizeOffset]
	MOV [.fileSize],EAX		; store it
	
	
	MOV EBX,.idLengthOffset		; get length of ID offset into EBX to add it to EDX
	ADD EDX,EBX					; add it
	
	
	MOV ECX,0					; clear ECX
	MOV CL, BYTE [EDX]			; get the length of the ID into CX
	INC EDX						; go to next byte
	
	
	CMP CL,2					; if the length of the id isn't at least 2, skip it to save time
	JB .readEntry				; read the next entry
	
	
	MOV ESI,[ESP]				; get ESI from the stack, but keep it there
	
	
	.checkByte:					; jump here to check the bytes against the file we're looking for
	CMP ECX,1					; see if we have read all bytes -1, the filename ends with 0
	JE .match					; if we read all the bytes, this is a match

	
	DEC ECX						; decrement number of bytes left
	
	MOV EAX,0					; clear EAX
	LODSB						; copies the byte at ESI to AL and increments ESI
	
	MOV EBX,0					; clear EBX
	MOV BL, BYTE[EDX]			; get the byte at EDX
	INC EDX						; go to next byte


	CMP BL,AL					; compare bytes
	JNE	.readEntry				; if bytes aren't equal, read the next entry
	
	JMP .checkByte				; read the next byte
	
	
	
	.noMatch:					; jump here when no match is found
	MOV EAX,0					; set EAX to 0 because it means no match was found
	MOV ECX,0					; return 0 as file size
	JMP .return					; return now
	
	
	.match:						; jump here when a match was found

	MOV EAX,[.startBlock]		; return with starting block number in EAX
	MOV ECX,[.fileSize]			; return with the file size in ECX
	
	
	.return:					; jump here to return
	POP ESI						; get ESI back off the stack
RET



; PROCEDURE: ReadFileInfoFromDisk -- Reads the disk to find the block number and size of the file specified by
;										ESI. IF EAX=0 it means the file is in the system directory. Otherwise
;										the file is in the driver directory. Returns EAX=block and EBX=size in
;										bytes if the file is found. Hangs system if not found.
ReadFileInfoFromDisk:

	PUSH ESI					; store filename on stack
	
	CMP EAX,0					; see if system dir is specified
	JNE .readDriver				; if not, read the driver directory


	.readSystem:				; read the system dir into memory
	
	MOV EAX,READ_LOC			; get the read location
	MOV EBX,[systemDirBlock]	; get the block number
	CALL ReadOneSector			; read the sector
	
	JMP .searchForFile			; now look for the file
	
	
	.readDriver:				; read the driver dir into memory
	MOV EAX,READ_LOC			; get the read location
	MOV EBX,[driverDirBlock]	; get the block number
	CALL ReadOneSector			; read the sector
	
	
	.searchForFile:				; look in the loaded directory for the file
	
	MOV ESI,[ESP]				; make sure we have the string address in ESI
	CALL ReadPath				; now read the path to find the file info
	
	CMP EAX,0					; see if block number returned was 0
	JE .error					; if it was, there's an error
	
	
	; otherwise store the info for returning
	MOV EBX,ECX					; file size gets returned from the procedure in EBX
	; EAX is already set with the block number

	JMP .return					; return if no error
	

	.error:						; jump here on error
	MOV ESI,errFind1			; get error string 1
	CALL PrintString			; print it
	
	POP ESI						; get file name from the stack
	CALL PrintString			; print it
	
	MOV ESI,errFind2			; get error string 2
	CALL PrintString			; print it
	
	.hang:
	JMP .hang					; hang the system on error
	
	
	.return:
	POP ESI						; get file name back off the stack
RET



; PROCEDURE: ReadFileToMem -- Reads the file from the disk into memory. EBX specifies the starting block
;								of the file, ECX specifies the size in bytes of the file, EDX specifies
;								the location at which to read file into memory.
ReadFileToMem:

	PUSH EBX					; store block number on stack
	PUSH EDX					; store destination on stack
	

	MOV EDX,0					; clear EDX, it will store the remainder of the division
	
	MOV EAX,ECX					; put size of file into EAX
	MOV EBX,2048				; get size of block in EBX
	
	DIV EBX						; divide EAX by EBX to get total number of blocks to read
	
	
	CMP EDX,0					; see if there is a remainder
	JE .beginRead				; if not, begin reading the file
	
	
	INC EAX						; otherwise, increment the number of blocks to read
	
	
	.beginRead:					; jump here to begin reading the file
	
	
	CMP EAX,1					; check to see if we are reading 1 sector
	JA .readMultiple			; if reading more than one sector, jump ahead
	
	
	
	.readOne:					; otherwise read one sector
	POP EAX						; get read location off stack
	POP EBX						; get starting block number off stack
	
	CALL ReadOneSector			; read the sector
	
	JMP .return					; return now
	
	
	
	.readMultiple:				; jump here to read multiple sectors
	MOV ECX,EAX					; get number of sectors to read into ECX
	
	POP EAX						; get read location off stack
	POP EBX						; get starting block number off stack
	
	CALL ReadSectors			; now read the sectors
	
	
	
	.return:
RET
