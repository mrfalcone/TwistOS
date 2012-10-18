;========================================================================
; function_macros.asm 
; ----------------------------------
; Defines macros for dealing with function calls from C.
;
;
; Author   : Mike Falcone
; Email    : mr.falcone@gmail.com
; Modified : 4/27/09
;========================================================================



;; macro that should be called at the beginning of every implementation
;  of a C function. Sets EBP to beginning of last item in parameter list.
%macro C_FUNC_ENTER 0
	PUSH EBP					; be sure to store EBP so it will remain unchanged
	MOV EBP,ESP					; set EBP to point to the stack so we can access variables
	PUSH EBX					; store EBX to keep it unchanged
	PUSH ESI					; store ESI to keep it unchanged
	PUSH EDI					; store EDI to keep it unchanged
%endmacro


;; macro that should be called at the end of every implementation
;  of a C function.
%macro C_FUNC_EXIT 0
	POP EDI						; restore original EDI
	POP ESI						; restore original ESI
	POP EBX						; restore original EBX
	MOV ESP,EBP					; restore original stack pointer
	POP EBP						; restore original EBP
%endmacro



;; macro to get the specified parameter into EAX from a C function.
;  the argument specifies the index in the parameter list. an argument
;  of 0 specifies the first parameter in the list of passed parameters.
;  1 means the second parameter from the list, etc.
%macro C_GET_PARAM 1

	; get the parameter. 8 is added because we want to bypass the old EBP
	; and return pointer that are on the stack
	MOV EAX,[EBP + (%1 * 4) + 8]


%endmacro

