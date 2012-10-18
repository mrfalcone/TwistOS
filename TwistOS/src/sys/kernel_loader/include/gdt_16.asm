;========================================================================
; gdt_16.asm -- 16 bit code for setting the GDT and the TSS.
;
;
; PROCEDURES:
;-------------
;	LoadGDT -- Loads the GDT.
;
;
; Updated: 05/20/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================



;; describe the global descriptor table
;-------------------------------
GDT:							; mark the beginning of the GDT

	;; null segment
	 DQ 0						; first 64 bits should be 0
	
	;; ring 0 code segment
	 DW 0FFFFh					; LIMIT     : maximum limit
	 DW 0						; BASE ADDR : 0
	 DB 0						; BASE ADDR : 0
	 DB 10011010b				; TYPE      : code segment, nonconforming, readable
	 DB 11001111b				; FLAGS     : page granularity, 32 bit protected mode
	 DB 0						; BASE
	 
	;; ring 0 data segment
	 DW 0FFFFh					; LIMIT     : maximum limit
	 DW 0						; BASE ADDR : 0
	 DB 0						; BASE ADDR : 0
	 DB 10010010b				; TYPE      : data segment, expands down, writable
	 DB 11001111b				; FLAGS     : page granularity, 32 bit protected mode
	 DB 0						; BASE

	
	;; tss
	 DW TSS_Size				; bits 0-15 of segment limit
	 DW TSS_Pos					; base
	 DB 0						; unused base
	 DB 10001001b				; set type, set priv level to 0, set present bit
	 DB 0						; unused bits
	 DB 0						; unused base
	
EndGDT:							; mark the end of the GDT so size can be determined
;-------------------------------


;; GDT descriptor entry
GDTDescriptor:					; GDT descriptor for use with the LGDT instruction
	GDTSize	  DW EndGDT-GDT-1	; size of the GDT
	GDTOffset DD GDT			; offset of the GDT
	
	
	
;; reserve task state segment
;-------------------------------
	TSS_Size	EQU 104
	
	TSS_Pos:
	%rep TSS_Size
	DB 0
	%endrep
;-------------------------------
	
	
;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: LoadGDT -- loads the GDT and returns to caller
;
LoadGDT:
	PUSHA						; push registers onto the stack
	
	LGDT [GDTDescriptor]		; load the GDT descriptor
	
	POPA						; pop registers from the stack
RET

