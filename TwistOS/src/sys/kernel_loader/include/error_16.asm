;========================================================================
; diskaccess_16.asm -- 16 bit procedures regarding checking for errors
;						and printing error messages.
;
; Requires screen_16.asm to also be included.
;
;
; PROCEDURES:
;-------------
;	CheckError -- Called to check for errors.
;
;
; Updated: 03/03/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: CheckError -- Called to check for errors. An error is detected if AX is not
;							equal to 0. SI should point to error string to display.
;							If an error is found, display message
;							and hang.
CheckError:
	CMP AX,0					; see if AX is 0
	JE .return					; if it is, there is no error so we can return
	
	; otherwise continue here as there is an error
	STI							; enable interrupts in case they are disabled
	CALL Clear16				; clear the screen
	CALL Print16				; print the error string at SI
	
	.ErrorHang:
	JMP .ErrorHang				; hang system on error
	
	.return:					; label for returning
RET
