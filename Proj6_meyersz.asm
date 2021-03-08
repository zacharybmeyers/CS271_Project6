TITLE Project6     (Proj6_meyersz.asm)

; Author: Zachary Meyers
; Last Modified: 02021-03-03
; OSU email address: meyersz@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 2021-03-14
; Description: ..............................

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

.data

	prompt1		BYTE	"Please enter a signed number: ",0
	user_str	BYTE	MAXSIZE DUP(0)
	num_bytes	DWORD	?
	error_msg	BYTE	"ERROR: you didn't enter a signed number, or your number was too big!",13,10,0
	user_num	SDWORD	?

.code
main PROC
	
	PUSH	OFFSET error_msg
	PUSH	OFFSET user_num
	PUSH	OFFSET prompt1
	PUSH	OFFSET user_str
	PUSH	MAXSIZE
	PUSH	OFFSET num_bytes
	CALL	ReadVal

	; debugging
	MOV		EAX, user_num
	CALL	WriteInt

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
	LOCAL negative:DWORD	; setup local var negative to use as flag
	PUSHAD					; push GP registers

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
	MOV		negative, 0			; set local negative flag to 0
	MOV		EAX, 0				
	MOV		EBX, 0				; use EBX for running total
_stringLoop:
	LODSB
	CMP		AL, 2Dh			; if byte is "-", set local flag
	JE		_negative
	CMP		AL, 2Bh			; if byte is "+", keep looping
	JE		_positive
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
	

	; NEED TO FIGURE OUT HOW TO CHECK FOR OVERFLOW

	; loop finished, check for overflow, convert if necessary, store
	CMP		negative, 1
	JNE		_posOverflowCheck
_negOverflowCheck:
	CMP		EBX, 80000000h	
	JG		_error			; error if negative overflow
	NEG		EBX				; if local negative flag is set, negate EBX
	JMP		_storeNum
_posOverflowCheck:
	CMP		EBX, 7FFFFFFFh
	JLE		_storeNum
	JMP		_error
_storeNum:
	MOV		[EDI], EBX		; store converted string in user_num
	JMP		_end
_negative:
	MOV		negative, 1		; set local negative flag
	LOOP	_stringLoop		; keep looping
_positive:
	LOOP	_stringLoop		; do nothing keep looping
_error:
	MOV		EDX, [EBP+28]	; error message in EDX
	CALL	WriteString
_end:
	POPAD		; pop GP registers
	RET 24
ReadVal ENDP

END main
