;========================================================================
; timer_32.asm -- timing procedures.
;
;
;
; PROCEDURES:
;-------------
;	ISRTimer -- Called when the timer IRQ is received.
;	SleepSecond -- Sleeps for one second before returning.
;	StartSecCounter -- Start counter of seconds.
;	GetCounterValue -- Return the number of seconds passed since timer started, in EAX.
;	StopSecCounter -- Stop counter of seconds.
;
;
; Updated: 04/07/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================


;------------------------------
; VARIABLES
;------------------------------
boolTiming		DB 0			; this will be 0 if not timing, 1 if we are timing
boolSecond		DB 0			; this is 0 if we have not timed for a second, 1 if we have

secondsPassed	DB 0			; this will store the number of seconds that have passed since the timer started



;------------------------------
; PROCEDURES
;------------------------------

; PROCEDURE: ISRTimer -- Called when the timer IRQ is received.
;
ISRTimer:
	CALL PollKeyboard			; poll the keyboard
	

	CMP BYTE [boolTiming],1		; see if we are currently timing
	JE .start					; if we are, go to start of code


	JMP .return					; and return
	

	;; decisecond counter:
	.deciseconds	DB 0		; stores the current decisecond count (1/100 second)
	

	.start:						; start of code
	
	MOV AL,[.deciseconds]		; get the current decisecond count into AL
	
	INC AL						; increase decisecond counter every 10 milliseconds
	
	
	CMP AL,100					; compare the decisecond count to 100 (100 ds in 1 s)
	JB .store					; if it's below, go ahead and store the numbers
	
	MOV AL,0					; otherwise, reset ds count back to 0
	
	MOV [boolSecond],BYTE 1		; set the second variable to true
	
	INC BYTE [secondsPassed]	; increase the number of seconds passed
	

	.store:
	MOV [.deciseconds],AL		; store the ds count
	
	
	.return:					; jump here to return

RET


; PROCEDURE: SleepSecond -- Sleeps for one second before returning.
;
SleepSecond:

	MOV [boolTiming],BYTE 1		; enable the timer
	
	
	.sleep:						; sleep for the second
	 
	 ; when a second has passed, the ISR will set the boolSecond variable to a 1
	 CMP BYTE [boolSecond],1	; see if a second has passed yet
	 JE .wakeup					; if it has, wake up
	 
	JMP .sleep					; continue sleeping

	
	.wakeup:					; jump here when done sleeping
	MOV [boolTiming],BYTE 0		; disable timer
	MOV [boolSecond],BYTE 0		; reset second variable
	
	MOV [secondsPassed],BYTE 0	; reset seconds passed back to 0

RET


; PROCEDURE: StartSecCounter -- Start counter of seconds.
;
StartSecCounter:

	STI							; enable interrupts

	MOV [secondsPassed],BYTE 0	; reset seconds passed back to 0

	MOV [boolTiming],BYTE 1		; enable the timer
	
RET


; PROCEDURE: GetCounterValue -- Return the number of seconds passed
;								since timer started, in EAX.
GetCounterValue:

	MOV EAX,0					; clear EAX
	MOV AL,[secondsPassed]		; get seconds passed into EAX

RET


; PROCEDURE: StopSecCounter -- Stop counter of seconds.
;
StopSecCounter:
	
	MOV [boolTiming],BYTE 0		; disable the timer
	MOV [secondsPassed],BYTE 0	; reset seconds passed back to 0
	
RET

