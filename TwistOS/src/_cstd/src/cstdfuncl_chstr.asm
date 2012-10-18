;========================================================================
; cstdfuncl_chstr.asm 
; ----------------------------------
; Implementation of the standard character and string functions declared
; in standard headers <cctype> and <cstring>. Designed for speed of
; execution.
;
;
; -- Assembled with NASM 2.06rc2 --
; Author   : Mike Falcone
; Email    : mr.falcone@gmail.com
; Modified : 4/27/09
;========================================================================



; -------------------------------
; Functions declared in <cctype>
; -------------------------------
[GLOBAL isalnum]
[GLOBAL isalpha]
[GLOBAL iscntrl]
[GLOBAL isdigit]
[GLOBAL isgraph]
[GLOBAL islower]
[GLOBAL isprint]
[GLOBAL ispunct]
[GLOBAL isspace]
[GLOBAL isupper]
[GLOBAL isxdigit]
[GLOBAL tolower]
[GLOBAL toupper]



; -------------------------------
; Functions declared in <cstring>
; -------------------------------
[GLOBAL memchr]
[GLOBAL memcmp]
[GLOBAL memcpy]
[GLOBAL memset]
[GLOBAL strcat]
[GLOBAL strchr]
[GLOBAL strcmp]
[GLOBAL strcoll]
[GLOBAL strcpy]
[GLOBAL strcspn]
[GLOBAL strerror]
[GLOBAL strlen]
[GLOBAL strncat]
[GLOBAL strncmp]
[GLOBAL strncpy]
[GLOBAL strpbrk]
[GLOBAL strrchr]
[GLOBAL strspn]
[GLOBAL strstr]
[GLOBAL strtok]


;; included to define macros for entering and exiting C functions
%include 'include/function_macros.asm'

[SECTION .text]

; ***********************************
; *  STANDARD CHARACTER FUNCTIONS   *
; ***********************************

isalnum:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'
	
	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testLowercase:				; begin testing lowercase letters
		CMP EAX,61h				; compare to lower case 'a'
		JB .testUppercase		; if below, it might be an uppercase letter
		CMP EAX,7Ah				; compare to lowercase 'z'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testUppercase:				; begin testing uppercase letters
		CMP EAX,41h				; compare to upper case 'A'
		JB .testDigit			; if below, it might be a digit
		CMP EAX,5Ah				; compare to uppercase 'Z'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testDigit:					; begin testing digits
		CMP EAX,30h				; compare to ascii 0
		JB .retFalse			; if below, return false
		CMP EAX,39h				; compare to ascii 9
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET



isalpha:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testLowercase:				; begin testing lowercase letters
		CMP EAX,61h				; compare to lower case 'a'
		JB .testUppercase		; if below, it might be an uppercase letter
		CMP EAX,7Ah				; compare to lowercase 'z'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testUppercase:				; begin testing uppercase letters
		CMP EAX,41h				; compare to upper case 'A'
		JB .retFalse			; if below, return false
		CMP EAX,5Ah				; compare to uppercase 'Z'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


iscntrl:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testControls:				; begin testing control characters
		CMP EAX,0				; EAX must be at least 0
		JB .retFalse			; if it's below, return false
		CMP EAX,1Fh				; compare last control character
		JA .testDelete			; if above, it might be delete character
		JMP .retTrue			; otherwise return true
	
	.testDelete:				; see if it's the delete character
		CMP EAX,7Fh				; compare to delete character
		JNE .retFalse			; if not, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


isdigit:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'
	
	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testDigit:					; begin testing digits
		CMP EAX,30h				; compare to ascii 0
		JB .retFalse			; if below, return false
		CMP EAX,39h				; compare to ascii 9
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


isgraph:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'
	
	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testGraph:					; begin testing graph characters
		CMP EAX,21h				; compare to '!', character just after space
		JB .retFalse			; if below, return false
		CMP EAX,7Eh				; compare to '~', last character before delete
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


islower:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testLowercase:				; begin testing lowercase letters
		CMP EAX,61h				; compare to lower case 'a'
		JB .retFalse			; if below, return false
		CMP EAX,7Ah				; compare to lowercase 'z'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


isprint:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'
	
	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testPrint:					; begin testing printable characters
		CMP EAX,20h				; compare to space character
		JB .retFalse			; if below, return false
		CMP EAX,7Eh				; compare to '~', last character before delete
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


ispunct:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'
	
	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testHighestpunc:			; begin testing highest punctuation in ascii character list
		CMP EAX,7Bh				; compare to '{'
		JB .testHighpunc		; if below, test different punctuation marks
		CMP EAX,7Eh				; compare to '~'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testHighpunc:				; begin testing high punctuation in ascii character list
		CMP EAX,5Bh				; compare to '['
		JB .testLowpunc			; if below, test different punctuation marks
		CMP EAX,60h				; compare to '`'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testLowpunc:				; begin testing low punctuation in ascii character list
		CMP EAX,3Ah				; compare to ':'
		JB .testLowestpunc		; if below, test different punctuation marks
		CMP EAX,40h				; compare to '@'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testLowestpunc:			; begin testing lowest punctuation in ascii character list
		CMP EAX,21h				; compare to '!'
		JB .retFalse			; if below, test different punctuation marks
		CMP EAX,2Fh				; compare to '/'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


isspace:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	C_GET_PARAM 0				; get first parameter into EAX
	

	.testSpace:					; see if it's the space character
		CMP EAX,20h				; compare to space character
		JNE .retFalse			; if not equal, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


isupper:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testUppercase:				; begin testing uppercase letters
		CMP EAX,41h				; compare to upper case 'A'
		JB .retFalse			; if below, return false
		CMP EAX,5Ah				; compare to uppercase 'Z'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


isxdigit:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'
	
	C_GET_PARAM 0				; get first parameter into EAX
	
	
	.testLowercaseHex:			; begin testing lowercase hex digits
		CMP EAX,61h				; compare to lowercase 'a'
		JB .testUppercaseHex	; if below, it might be an uppercase digit
		CMP EAX,66h				; compare to lowercase 'f'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testUppercaseHex:			; begin testing uppercase hex digits
		CMP EAX,41h				; compare to uppercase 'A'
		JB .testDecimalDigit	; if below, it might be a decimal digit
		CMP EAX,46h				; compare to uppercase 'F'
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	.testDecimalDigit:			; begin testing decimal digits
		CMP EAX,30h				; compare to ascii 0
		JB .retFalse			; if below, return false
		CMP EAX,39h				; compare to ascii 9
		JA .retFalse			; if above, return false
		JMP .retTrue			; otherwise return true
	
	
	.retFalse:					; jump here to return false
	MOV EAX,0					; zero means false
	JMP .return					; now return
	
	
	.retTrue:					; jump here to return true
	MOV EAX,1					; nonzero means true
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


tolower:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	C_GET_PARAM 0				; get first parameter into EAX
	
	
	;; first test to see if the letter is uppercase in order to make it lowercase
	.testUppercase:				; begin testing uppercase letters
		CMP EAX,41h				; compare to upper case 'A'
		JB .return				; if below, return now
		CMP EAX,5Ah				; compare to uppercase 'Z'
		JA .return				; if above, return now
	
	
	OR EAX,100000b				; set bit 5 to make lowercase
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


toupper:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	C_GET_PARAM 0				; get first parameter into EAX
	
	
	;; first test to see if the letter is lowercase in order to make it uppercase
	.testLowercase:				; begin testing lowercase letters
		CMP EAX,61h				; compare to lowercase 'a'
		JB .return				; if below, return now
		CMP EAX,7Ah				; compare to lowercase 'z'
		JA .return				; if above, return now
	
	
	XOR EAX,100000b				; clear bit 5 to make uppercase 
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET




; ***********************************
; *    STANDARD STRING FUNCTIONS    *
; ***********************************

memchr:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	
	C_GET_PARAM 0				; get first parameter into EAX (buffer pointer)
	MOV EDX,EAX					; temporarily store it in EDX
	
	
	C_GET_PARAM 1				; get second parameter into EAX (ch)
	MOV EBX,EAX					; put character we want into EBX
	
	C_GET_PARAM 2				; get third parameter into EAX (count)
	MOV ECX,EAX					; put count into ECX

	
	MOV EAX,EDX					; get buffer pointer into EAX

	.search:					; this loop searches for the character
	JECXZ .notFound				; when counter reaches zero, nothing was found
	DEC ECX						; decrement the counter 
	
	
	CMP BYTE [EAX],BL			; see if the current byte in the buffer is the one we're looking for
	JE .return					; if it is, return now
	
	INC EAX						; otherwise increase our position in the buffer
	JMP .search					; and keep searching
	
	
	
	.notFound:					; jump here when character is not found
	MOV EAX,0					; 0 means not found
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


memcmp:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	
	C_GET_PARAM 0				; get first parameter into EAX (buf1)
	MOV ESI,EAX					; store it in ESI
	
	
	C_GET_PARAM 1				; get second parameter into EAX (buf2)
	MOV EDI,EAX					; store it in EDI
	
	C_GET_PARAM 2				; get third parameter into EAX (count)
	MOV ECX,EAX					; put count into ECX

	MOV EAX,0					; clear EAX for loop
	MOV EBX,0					; clear EBX for loop
	
	
	.compare:					; begin comparing strings
	JECXZ .equal				; when counter reaches zero, all the bytes were equal
	DEC ECX						; decrement the counter
	
	MOV AL,BYTE [ESI]			; get byte from buf1
	MOV BL,BYTE [EDI]			; get byte from buf2
	
	CMP AL,BL					; compare the current byte in each buffer
	JA .buf2Greater				; if buf2's byte is greater than buf1's, exit the loop
	JB .buf1Greater				; if buf1's byte is greater than buf2's, exit the loop
	
	; otherwise they are equal and we can move on
	
	INC ESI						; increase our position in buf1
	INC EDI						; increase our position in buf2
	
	JMP .compare				; and keep looping
	
	
	
	.buf1Greater:				; jump here when buf1 is greater than buf2
	MOV EAX,1					; greater than zero means buf1 is greater
	JMP .return					; now return

	
	.buf2Greater:				; jump here when buf2 is greater than buf1
	MOV EAX,-1					; less than zero means buf1 is less than buf2
	JMP .return					; now return
	
	
	.equal:						; jump here when buffers are equal
	MOV EAX,0					; 0 means equal
	
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


memcpy:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	
	C_GET_PARAM 0				; get first parameter into EAX (to pointer)
	MOV EDI,EAX					; store in EDI
	MOV EDX,EDI					; store a pointer to 'to' in EDX so we can return it later
	
	
	C_GET_PARAM 1				; get second parameter into EAX (from pointer)
	MOV ESI,EAX					; store in ESI
	
	C_GET_PARAM 2				; get third parameter into EAX (count)
	MOV ECX,EAX					; put count into ECX
	

	
	; copy multiple bytes
	CMP ECX,4					; see if the count is at least 4, so we can use an entire register
	JB .copySingle				; if not, just copy single bytes
	
	.copyMultiple:				; this loop copies 4 bytes at a time in a whole register
	JECXZ .return				; if we have copies all the bytes, return now
	
	MOV EAX,[ESI]				; get 4 bytes from the source array
	MOV [EDI],EAX				; place them into the destination array
	
	ADD ESI,4					; increase position in source by 4 bytes
	ADD EDI,4					; increase position in destination by 4 bytes
	
	
	CMP ECX,4					; see if there are at least 4 bytes left to copy
	JB .copySingle				; if not, copy bytes singly
	
	SUB ECX,4					; otherwise decrease counter by 4
	JMP .copyMultiple			; loop back to copy more
	
	
	; copy single bytes
	.copySingle:				; this loop copies ECX amount of bytes singly
	JECXZ .return				; when done copying all characters, it's time to return
	DEC ECX						; decrement counter
	
	MOV AL,BYTE[ESI]			; get the byte at ESI
	MOV BYTE[EDI],AL			; put it at EDI
	
	INC ESI						; increase our position in ESI
	INC EDI						; increase our position in EDI
	
	JMP .copySingle				; loop back to copy another byte

	
	.return:
	MOV EAX,EDX					; get pointer to 'to' to return
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


memset:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	
	C_GET_PARAM 0				; get first parameter into EAX (buffer pointer)
	MOV EDI,EAX					; store in EDI
	MOV EDX,EDI					; store pointer in EDX so we can return it later
	
	
	C_GET_PARAM 1				; get second parameter into EAX (character)
	MOV ESI,EAX					; temporarily store in ESI
	
	C_GET_PARAM 2				; get third parameter into EAX (count)
	MOV ECX,EAX					; put count into ECX
	

	CMP EAX,0					; if EAX is already zero we can start setting bytes
	JE .startSetting			; start setting bytes if so
	
	
	MOV EAX,ESI					; get character back from ESI
	
	
	; this code fills EAX entirely with the byte to memset
	MOV AH,AL					; put low byte into AH
	MOV BX,AX					; put word into EBX
	SHL EAX,16					; shift bytes to high word of EAX
	MOV AX,BX					; get the word of same bytes and put in low word of EAX
	; now EAX is filled with the byte to memset
	
	
	.startSetting:				; begin to set bytes
	
	; set multiple bytes
	CMP ECX,4					; see if the count is at least 4, so we can use an entire register
	JB .setSingle				; if not, just set single bytes
	
	
	
	.setMultiple:				; this loop sets 4 bytes at a time in a whole register
	JECXZ .return				; if we have set all the bytes, return now
	
	MOV [EDI],EAX				; place bytes into the buffer

	ADD EDI,4					; increase position in buffer by 4 bytes
	
	CMP ECX,4					; see if there are at least 4 bytes left to set
	JB .setSingle				; if not, set bytes singly
	
	SUB ECX,4					; otherwise decrease counter by 4
	JMP .setMultiple			; loop back to set more
	
	
	; set single bytes
	.setSingle:					; this loop sets ECX amount of bytes singly
	JECXZ .return				; when done setting all characters, return
	DEC ECX						; decrement counter
	
	MOV BYTE[EDI],AL			; put byte into buffer

	INC EDI						; increase our position in EDI
	
	JMP .setSingle				; loop back to set another byte

	
	.return:
	MOV EAX,EDX					; get pointer to buffer to return
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


strcat:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	
	C_GET_PARAM 0				; get first parameter into EAX (str1)
	MOV EDI,EAX					; store in EDI
	MOV EDX,EDI					; store pointer in EDX so we can return it later
	
	
	C_GET_PARAM 1				; get second parameter into EAX (str2)
	MOV ESI,EAX					; store in ESI
	
	
	MOV ECX,0					; clear ECX for loop
	
	.getStr1End:				; this loop finds the end of string 1
	MOV CL,BYTE [EDI]			; get current byte of str1
	JECXZ .concatenate			; if it's the end, start concatenating
	
	INC EDI						; otherwise increase our position in str1
	JMP .getStr1End				; and loop back to get the end
	
	
	
	.concatenate:				; this loop concatenates the characters from str2 onto str1
	MOV CL,BYTE [ESI]			; get current byte of str2
	JECXZ .done					; if this is the end of str2, we're done
	
	MOV BYTE[EDI],CL			; otherwise put the byte into str1
	
	INC EDI						; otherwise increase our position in str1
	INC ESI						; otherwise increase our position in str2
	
	JMP .concatenate			; keep looping
	
	
	
	.done:						; jump here when done
	MOV BYTE [EDI],0			; end EDI with a null character
	
	
	.return:
	MOV EAX,EDX					; get pointer to return
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


strchr:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	
	C_GET_PARAM 0				; get first parameter into EAX (string pointer)
	MOV ESI,EAX					; temporarily store it in ESI
	
	
	C_GET_PARAM 1				; get second parameter into EAX (ch)
	MOV EBX,EAX					; put character we want into EBX
	
	
	MOV EAX,ESI					; get buffer pointer into EAX
	MOV ECX,0					; clear ECX for loop

	.search:					; this loop searches for the character
	MOV CL,BYTE[EAX]			; get current byte from string into CL
	JECXZ .notFound				; if byte is zero, we're at the end and nothing was found

	
	CMP CL,BL					; see if the byte in the string is the one we're looking for
	JE .return					; if it is, return now
	
	INC EAX						; otherwise increase our position in the buffer
	JMP .search					; and keep searching
	
	
	
	.notFound:					; jump here when character is not found
	MOV EAX,0					; 0 means not found
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


strcmp:
	C_FUNC_ENTER				; macro defined in 'function_macros.asm'

	
	C_GET_PARAM 0				; get first parameter into EAX (str1)
	MOV ESI,EAX					; store it in ESI
	
	
	C_GET_PARAM 1				; get second parameter into EAX (str2)
	MOV EDI,EAX					; store it in EDI


	.startComparing:			; begin comparing strings
	MOV AL,BYTE [ESI]			; get byte from str1
	MOV BL,BYTE [EDI]			; get byte from str2
	
	CMP AL,0					; see if str1's byte is null
	JNE .compare				; if not, compare the two bytes
	
	CMP BL,0					; otherwise see if str2's byte is also null
	JNE .str2Greater			; if not, string 2 is greater so exit the loop
	
	JMP .equal					; if we get to this point, the strings are both equal
	
	
	.compare:					; jump here to compare both bytes
	CMP AL,BL					; compare the current byte in each buffer
	JA .str2Greater				; if str2's byte is greater than str1's, exit the loop
	JB .str1Greater				; if str1's byte is greater than str2's, exit the loop
	
	; otherwise they are equal and we can move on
	
	INC ESI						; increase our position in str1
	INC EDI						; increase our position in str2
	
	JMP .startComparing			; and keep looping
	
	
	
	.str1Greater:				; jump here when str1 is greater than str2
	MOV EAX,1					; greater than zero means str1 is greater
	JMP .return					; now return

	
	.str2Greater:				; jump here when str2 is greater than str1
	MOV EAX,-1					; less than zero means str1 is less than str2
	JMP .return					; now return
	
	
	.equal:						; jump here when strings are equal
	MOV EAX,0					; 0 means equal
	
	
	.return:
	C_FUNC_EXIT					; macro defined in 'function_macros.asm'
RET


strcoll:
	
RET


strcpy:
	
RET


strcspn:
	
RET


strerror:
	
RET


strlen:
	
RET


strncat:
	
RET


strncmp:
	
RET


strncpy:
	
RET


strpbrk:
	
RET


strrchr:
	
RET


strspn:
	
RET


strstr:
	
RET


strtok:
	
RET

