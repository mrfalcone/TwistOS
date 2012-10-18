;========================================================================
; TKLD_header.asm -- defines the EBC header for the kernel loader program.
;						All EBC files have a header following this format.
;
; EBC Header Format:
; ------------------
; - Doubleword defining size of header in bytes. This dword is included in the size of the header.
;
; - Byte defining length of description string. (1 if no description)
; - Description string. 0 if none.
;
; - Byte defining length of version string. (1 if no version)
; - Version string. 0 if none.
;
; - Byte defining length of author name. (1 if no author)
; - Author name. 0 if none.
;
; - Word defining size of embedded icon file in bytes. (1 if no icon file)
; - Embedded icon file. 0 if none.
;
; - Word defining size of embedded header extension.  (1 if no extension)
; - Embedded header extension. 0 if none.
;
; - Null Doubleword (included in header size)
;
;
;
; Updated: 03/21/2009
; Author : Mike Falcone
; E-mail : mr.falcone@gmail.com
;========================================================================



HeaderStart:					; beginning of the EBC header

	DD HeaderEnd-HeaderStart	; define size of header
	

	;-------------------
	; EBC Description
	;-------------------
	DB .DescEnd-.Desc			; define length of EBC description string
	.Desc:
		DB "TwistOS Kernel Loader"
	.DescEnd:
	;-------------------

	;-------------------
	; EBC Version
	;-------------------
	DB .VerEnd-.Ver				; define length of EBC version string
	.Ver:
		DB "0.1a"
	.VerEnd:
	;-------------------

	;-------------------
	; EBC Author
	;-------------------
	DB .AuthEnd-.Auth			; define length of EBC author string
	.Auth:
		DB "Mike Falcone"
	.AuthEnd:
	;-------------------

	
	;; icon information:
	DB 1						; 1 because there is no icon file
	DB 0						; no icon

	
	;; extension information:
	DB 1						; 1 because there is no extension
	DB 0						; no extension


	DD 0						; null dword

HeaderEnd:						; end of the EBC header