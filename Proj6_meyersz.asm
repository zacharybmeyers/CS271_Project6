TITLE Project6     (Proj6_meyersz.asm)

; Author: Zachary Meyers
; Last Modified: 02021-03-09
; OSU email address: meyersz@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 2021-03-14
; Description:		MASM program includes procedures for reading a string into a SDWORD (ReadVal) 
;				and for reading a SDWORD into a string and displaying it (WriteVal). The main 
;				function continually prompts for string input using ReadVal to fill an array of ARRAYSIZE 
;				(constant) SDWORDs. 
;					ReadVal makes use of a macro mGetString which uses the irvine library procedure ReadString 
;				to get user input, then ReadVal validates that string input and converts it from a series 
;				of bytes to a SDWORD, before finally storing it in an array. 
;					WriteVal is used to convert each element in the array back to a string before printing 
;				it with the use of a macro mDisplayString (which utilizes the irvine library procedure WriteString) 
;				to print each converted value. 
;					Meanwhile, the sum is accumulated, then printed, and the rounded average is calculated based 
;				on the sum and the size of the array specified by a constant. Floor rounding is used for the average
;				in case a decimal value is encountered. The program finisheds and says goodbye.
;  
; Implementation note: the program accounts for arrays of various sizes (using constants) and can validate 
;						any string as a signed integer to ensure it fits in a 32 bit register and is in 
;						integer representation (including a '+' or '-' as the first character)

INCLUDE Irvine32.inc

; ********************************
; mGetString: macro is passed the address of a prompt to print for the user, 
;			uses ReadString to store keyboard input in the address of str_addr
;
; Preconditions: prompt_addr, str_addr, and num_bytes_addr must be passed by reference (OFFSET)
; Postconditions: output params: 
;					str_addr will point to the memory address of the user's string
;					num_bytes_addr will point to the memory address that holds the 
;					number of bytes in the user's string
; Receives: input params are prompt_addr, max_len
; Returns: 
; ********************************
mGetString MACRO prompt_addr, str_addr, max_len, num_bytes_addr
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX
	PUSH	EDI						; Save used registers

	MOV		EDX, prompt_addr
	CALL	WriteString
	MOV		EDX, str_addr
	MOV		ECX, max_len
	CALL	ReadString
	MOV		EDI, num_bytes_addr
	MOV		[EDI], EAX				; EAX holds # bytes read from ReadString

	POP		EDI						; Restore used registers
	POP		EAX
	POP		ECX
	POP		EDX
ENDM

; ********************************
; mDisplayString: macro is passed the address of a byte array and 
;					prints it with the use of WriteString
;
; Preconditions: buffer_addr must be passed by reference (OFFSET)
; Postconditions:
; Receives: buffer
; Returns: 
; ********************************
mDisplayString MACRO buffer_addr
	PUSH	EDX					; save EDX
	MOV		EDX, buffer_addr
	CALL	WriteString
	POP		EDX					; restore EDX
ENDM

MAXSIZE = 33
ARRAYSIZE = 10

.data

	intro1			BYTE	"Project 6: Designing low level I/O procedures by Zachary Meyers",13,10,13,10,0
	intro2			BYTE	"Please enter 10 signed decimal integers.",13,10
					BYTE	"Each number must be able to fit inside a 32 bit register.",13,10
					BYTE	"Once finished I'll diplay your list of numbers, ",13,10
					BYTE	"along with their sum and rounded average.",13,10,13,10,0
	prompt1			BYTE	"Please enter a signed number: ",0
	user_str		BYTE	MAXSIZE DUP(?)
	num_bytes		DWORD	?
	error_msg		BYTE	"ERROR: you didn't enter a signed number, or your number was too big!",13,10,0
	user_num		SDWORD	?
	numArray		SDWORD	ARRAYSIZE DUP(?)
	test_num		SDWORD	109
	out_string		BYTE	MAXSIZE DUP(?)
	array_prompt	BYTE	"You entered the following numbers:",13,10,0
	sum_prompt		BYTE	"The sum of these numbers is: ",0
	avg_prompt		BYTE	"The rounded average (floor) is: ",0
	sum				SDWORD	0
	sum_negative	SDWORD	0	; use as flag for rounding later
	average			SDWORD	?
	goodbye			BYTE	"Thanks for playing, see ya!",13,10,0

.code
main PROC

; introduction: use macro to print intro1 and intro 2
	mDisplayString OFFSET intro1
	mDisplayString OFFSET intro2

; fill the array with 10 integers using ReadVal
	MOV		EDI, OFFSET numArray
	MOV		ECX, LENGTHOF numArray
_fillArray:
	PUSH	OFFSET error_msg
	PUSH	OFFSET user_num
	PUSH	OFFSET prompt1
	PUSH	OFFSET user_str
	PUSH	MAXSIZE
	PUSH	OFFSET num_bytes
	CALL	ReadVal				; prompts user, validates string input, converts to SDWORD
	MOV		EAX, user_num
	MOV		[EDI], EAX			; move user_num into array
	ADD		EDI, TYPE numArray	; increment array address by type (go to next position)
	LOOP	_fillArray

; use macro to display array prompt
	CALL	CrLf
	mDisplayString OFFSET array_prompt

; display the array using WriteVal, and accumulate the sum
	MOV		ESI, OFFSET numArray
	MOV		ECX, ARRAYSIZE
_displayLoop:
	MOV		EAX, sum			
	ADD		EAX, [ESI]			
	MOV		sum, EAX			; acumulate each element in sum
	PUSH	[ESI]				; push the current element to WriteVal
	PUSH	OFFSET out_string
	PUSH	LENGTHOF out_string
	CALL	WriteVal			; display value as string
	CMP		ECX, 1
	JE		_noComma			; don't print a comma if last element
	MOV		AL, 2Ch				; ","
	CALL	WriteChar
_noComma:	
	MOV		AL, 20h	
	CALL	WriteChar			; " "
	ADD		ESI, TYPE numArray	; increment ESI to get next element
	LOOP	_displayLoop
	CALL	CrLf				; new line after displaying array

; use macro to diplay sum prompt, use WriteVal to display sum
	mDisplayString OFFSET sum_prompt
	PUSH	sum
	PUSH	OFFSET out_string
	PUSH	LENGTHOF out_string
	CALL	WriteVal
	CALL	CrLf

; determine if sum is positive or negative 
; (use for floor rounding the average later)
	MOV		EAX, sum
	ADD		EAX, 0
	JS		_setNegative
	JMP		_calculateAvg
_setNegative:
	MOV		sum_negative, 1

; calculate rounded average
_calculateAvg:
	MOV		EAX, sum
	MOV		EBX, ARRAYSIZE
	CDQ
	IDIV	EBX
	CMP		sum_negative, 1
	JE		_negativeRound		; if sum was negative, round average down
	JMP		_storeAvg
_negativeRound:
	DEC		EAX
_storeAvg:
	MOV		average, EAX	; sum / arraysize = average

; use macro to display average prompt, use WriteVal to display rounded average
	mDisplayString OFFSET avg_prompt
	PUSH	average
	PUSH	OFFSET out_string
	PUSH	LENGTHOF out_string
	CALL	WriteVal
	CALL	CrLf

; use macro to display farewell message
	CALL	CrLf
	mDisplayString OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ********************************
; ReadVal: uses the mGetString macro to read a user's sting, validates each ASCII byte, 
;			and converts the string to a SDWORD
;
; Preconditions: mGetString must be defined for getting user input, user_num must be SDWORD
; Postconditions: converted string is stored as a SDWORD in user_num
; Receives: addresses for... error_msg, user_num,prompt1, user_str, num_bytes... and
;			MAXSIZE constant as parameters on the system stack
; Returns: 
; ********************************
ReadVal PROC
	; setup local vars: negative to use as flag, str_bytes to store num_bytes for later use
	LOCAL negative:DWORD, str_bytes:DWORD	
	PUSHAD									; push GP registers

_getUserData:
	; Get user's string, use macro with addresses and 
	; identifiers from the stack frame:
	;	[EBP+20] = offset prompt1
	;	[EBP+16] = offset user_str
	;   [EBP+12] = MAXSIZE constant
	;	[EBP+8] = offset num_bytes
	mGetString [EBP+20], [EBP+16], [EBP+12], [EBP+8]

	MOV		ESI, [EBP+16]		; address of user's string in ESI
	MOV		EDI, [EBP+24]		; address of user_num in EDI
	MOV		EAX, [EBP+8]		; address of num_bytes in EAX
	MOV		ECX, [EAX]			; num_bytes in ECX (loop)
	MOV		str_bytes, ECX
	MOV		negative, 0			; set local negative flag to 0
	MOV		EAX, 0				
	MOV		EBX, 0				; use EBX for running total
	
	CLD		; clear direction flag
_stringLoop:
	LODSB
	CMP		ECX, str_bytes
	JE		_signCheck		; if first time through loop, check for a sign character
	JMP		_charValidate
	_signCheck:
		CMP		AL, 2Dh			; if byte is "-", set local negative flag
		JE		_negative
		CMP		AL, 2Bh			; if byte is "+", clear local negative flag
		JE		_positive
		JMP		_charValidate	; if no sign, proceed to validation
		_negative:
			MOV		negative, 1		; set local negative flag
			LOOP	_stringLoop		; keep looping
		_positive:
			MOV		negative, 0		; clear local negative flag
			LOOP	_stringLoop		; keep looping
_charValidate:
	CMP		AL, 30h
	JL		_error
	CMP		AL, 39h
	JG		_error			; if current byte is not an ASCII hex representation of 0-9, error
	SUB		AL, 30h			; otherwise, valid, convert byte
	PUSH	EAX				; save modified byte
	MOV		EAX, EBX
	MOV		EBX, 10
	MUL		EBX				
	MOV		EBX, EAX		; multiply running total by 10, store in EBX
	POP		EAX				; restore modified byte
	ADD		EBX, EAX		; running total * 10 +=  modified byte
	LOOP	_stringLoop
	
	; loop finished, check for overflow, convert if necessary, store
	CMP		negative, 1
	JE		_negOverflowCheck
	_posOverflowCheck:
		CMP		EBX, 7FFFFFFFh	
		JA		_error			; error if pos val > 2^31 - 1
		JMP		_storeNum
	_negOverflowCheck:
		CMP		EBX, 80000000h	
		JA		_error			; error if neg val < -(2^31)
		NEG		EBX				; if local negative flag is set, negate EBX
		JMP		_storeNum
_storeNum:
	MOV		[EDI], EBX		; store converted string in user_num
	JMP		_end
_error:
	MOV		EDX, [EBP+28]	; error message in EDX
	CALL	WriteString
	JMP		_getUserData	; get new input (start all the way over)
_end:
	POPAD		; pop GP registers
	RET 24
ReadVal ENDP

; ********************************
; WriteVal: takes a signed integer value, converts it to a string, and displays it
;
; Preconditions: 
; Postconditions: out_string contains ASCII char bytes after conversion
; Receives: user_num, address of out_string, size of out_string as parameters on system stack
; Returns: 
; ********************************
WriteVal PROC
	LOCAL	negative:DWORD	; setup local var as negative flag
	PUSHAD

	MOV		negative, 0		; clear local negative flag
	MOV		EDI, [EBP+12]	; address of out_string in EDI
	ADD		EDI, [EBP+8]	; add length of out_string to EDI
	DEC		EDI				; access last byte
	MOV		AL, 0
	STD						; move backwards through out_string
	STOSB					; store null terminator

	MOV		EAX, [EBP+16]	; num in EAX
	MOV		EBX, 10			; divisor (10) in EBX
	ADD		EAX, 0			; test sign flag
	JNS		_convert		; if val in EAX is positive, jump to convert
	; otherwise, set local negative flag and negate EAX, then convert
	MOV		negative, 1		
	NEG		EAX
_convert:
; keep dividing num, converting remainder, storing as byte
_divisionLoop:
	CDQ
	IDIV	EBX				; divide quotient by 10
	ADD		EDX, 30h		; convert remainder (last digit) to ASCII
	PUSH	EAX				; preserve quotient
	MOV		AL, DL			; store ASCII byte in AL
	STOSB					; store in out_string
	POP		EAX				; restore quotient
	CMP		EAX, 0
	JNE		_divisionLoop	; keep dividing/converting/storing bytes until quotient is 0
	
	; once loop ends, if negative flag was set, store "-" in EDI
	CMP		negative, 1
	JNE		_printStr		; if positive, print normal
	MOV		AL, 2Dh			
	STOSB					; if negative, store "-"

_printStr:	
	;increase EDI pointer once more to access first byte
	INC		EDI
	; use macro to display the converted num as a string
	mDisplayString EDI

	POPAD
	RET	12
WriteVal ENDP

END main
