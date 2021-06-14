TITLE String Primitives and Macros     (Proj6_silbers.asm)

; Author: Sam Silber
; Last Modified: 6/1/2021
; OSU email address: silbers@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:  6               Due Date: 6/6/2021
; Description: A program that uses string primitives and macros to get 10 signed integers from the user,
;		       stores the values in an array, and then displays the integer array along with their sum and average

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
;  Displays a prompt to the user for a signed number, then stores the user’s keyboard input into a memory location
;
; Preconditions: N/A
;
; Receives: 
;			prompt: A string prompting the user to input an integer (input, by reference)
;			maxInputLength: A count for the length of the input string that can be accomodated (input, by value)
;           input:  Location where the user’s keyboard input will be stored (output, by reference)
;			bytesRead: Number of bytes read by the macro (output, by value)
;
; returns: User's keyboard is stored in input; number of bytes read by the macro stored in bytesRead
; ---------------------------------------------------------------------------------
mGetString MACRO prompt:REQ, maxInputLength:REQ, input:REQ, bytesRead:REQ
	
	; Save used registers
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX

	; Prompt the user to input a signed integer
	MOV		EDX, prompt
	CALL	WriteString

	; Get signed integer from user as a string and store the reference to it in input
	MOV		EDX, input				
	MOV		ECX, maxInputLength			
	CALL	ReadString

	; Store number of bytes from user input
	MOV		bytesRead, EAX

	; Restore used registers
	POP		EAX
	POP		ECX
	POP		EDX

ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays the  string at the specified memory location to the user

; Preconditions: String must be passed as a reference
;
; Receives: 
;			string: specified memory location of the string (input, by reference)
;
; returns: N/A
; ---------------------------------------------------------------------------------
mDisplayString MACRO string:REQ
	
	; Save used registers
	PUSH	EDX

	; Display the string to the user
	MOV		EDX, string
	CALL	WriteString

	; Restore used registers
	POP		EDX

ENDM

MAX_LENGTH = 12					; numeric input as a string can be max 12 bytes long: 10 digits, a sign, and the null byte
NUM_INTS = 10

.data

intro1		BYTE	"Programming Assignment 6: Designing low-level I/O procedures", 13, 10, 0
intro2		BYTE	"By: Sam Silber", 13, 10, 0
intro3		BYTE	"Please provide 10 signed decimal integers. "
			BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 13, 10
			BYTE	"After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.", 13, 10, 0
prompt		BYTE	"Please enter a signed number: ", 0
error		BYTE	"ERROR: You did not enter a signed number or your number was too big. Try again. ", 0
user_input	BYTE 	MAX_LENGTH DUP(?)
bytes_read	DWORD	?
array		SDWORD	NUM_INTS DUP(?)
location	DWORD	0
num_as_str	BYTE	MAX_LENGTH DUP(?)
dis_array   BYTE    "You entered the following numbers:", 13, 10, 0
dis_sum		BYTE	"The sum of these numbers is: ", 0
dis_avg		BYTE	"The rounded average is: ", 0
goodbye		BYTE	"Thanks for playing!", 0
	
.code

main PROC
	
	; Display introductions to user
	mDisplayString OFFSET intro1
	mDisplayString OFFSET intro2
	CALL	CrLf
	mDisplayString OFFSET intro3
	CALL	CrLf

	; Read the user's value NUM_INTS number of times
	MOV		ECX, NUM_INTS

_getInts:
	
	; Get 10 valid signed integers from the user as strings; store them as integers in an array
	PUSH	location
	PUSH	OFFSET array
	PUSH	OFFSET error
	PUSH	bytes_read
	PUSH	MAX_LENGTH
	PUSH	OFFSET prompt
	PUSH	OFFSET user_input
	CALL	ReadVal
	CALL	CrLf

	; Increment the location in the array of valid integers by 4, then get next number from the user to store it there
	ADD		location, 4
	LOOP	_getInts

	; Once 10 valid values have been input, convert them to strings and display them to the user
	PUSH	OFFSET num_as_str
	PUSH	MAX_LENGTH
	PUSH	NUM_INTS
	PUSH	OFFSET dis_array
	PUSH	OFFSET array
	CALL	DisplayIntegers
	CALL	CrLf

	; Display the sum and rounded average of the inputs to the user
	PUSH	OFFSET dis_avg
	PUSH	OFFSET num_as_str
	PUSH	MAX_LENGTH
	PUSH	NUM_INTS
	PUSH	OFFSET dis_sum
	PUSH	OFFSET array
	CALL	DisplayStats
	CALL	CrLf

	; Say goodbye to the user
	mDisplayString OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Invokes the mGetString macro to get user input in the form of a string of digits.
; Converts the string of ASCII digits to its numeric value representation , validating the user’s input is a valid number
; Stores this one value in a memory variable
; 
; Preconditions: N/A
;
; Postconditions: EAX, EBX, ECX, EDX, EDI, and ESI have the same values before ReadVal was called
;
; Receives: location of the user's input (input, by reference)
;           String to display to the user to prompt for input (input, by reference
;			The maximum length a user's input may have (input, by value)
;           The number of bytes read by the user's input (input/output, by value)
;           String to display an error message to the user when input is invalid (input, by reference)
;           Array to store the user input, converted to a numeric (input/output, by reference)
;			Location in the area (in bytes) the next value being read will be stored in (input, by value)
;
; Returns: The provided array will contain the user's input, converted to an integer, in the array location provided
; ---------------------------------------------------------------------------------
ReadVal PROC
	PUSH    EBP
	MOV     EBP, ESP

	; Save used registers
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	EDI
	PUSH	ESI

_newInput:
	; Move reference to user input to ESI so it can be loaded
	MOV		ESI, [EBP + 8]			; reference to user input

	; Get user input
	mGetString [EBP + 12], [EBP + 16], ESI, [EBP + 20]

	; Make the number of bytes read the counter and get the reference to the storage array
	MOV		ECX, [EBP + 20]			; value of bytes_read
	MOV		EDI, [EBP + 28]			; reference to the array

	; Access the correct element of the array using the location (in bytes) number
	ADD		EDI, [EBP + 32]

	; Clear EAX and the direction flag for iteration through the string left to right
	MOV		EAX, 0
	CLD

	; Determine if the provided number is signed
	LODSB
	CMP		AL, 43					; string has leading +
	JE		_hasSign
	CMP		AL, 45					; string has leading -
	JE		_hasSign
	JMP		_validate				; Otherwise, go ahead and process the unsigned string

_hasSign:

	; If signed, go to the next character in the string and increment EDI
	DEC		ECX
	LODSB
	JMP		_validate

_stringLoop:

	; Go to the next character in the string and increment EDI
	LODSB

_validate:

	; Ensure the current character being assessed is a valid number (48 - 57 in ASCII)
	CMP		AL, 48
	JL		_invalidInput
	CMP		AL, 57
	JG		_invalidInput

	; Implement algorithm to create number from ASCII values
	MOVSX	EAX, AL					; Copy AL into EAX with sign-extend so registers add properly
	SUB		EAX, 48
	MOV		EBX, EAX

	MOV		EAX, 10
	MOV		EDX, [EDI]
	IMUL	EDX
	JO		_invalidInput			; If the calculation of the number leads to overflow, it's invalid
	ADD		EAX, EBX
	JO		_invalidInput			; If the calculation of the number leads to overflow, it's invalid

_isValid:
	MOV		[EDI], EAX
	
	LOOP	_stringLoop

	; If the input was negative, make it so. Otherwise, end the procedure
	MOV		ESI, [EBP + 8]			; go back to start of user input
	MOV		EAX, 0					; clear EAX
	LODSB
	CMP		AL, 45					; string has leading -
	JE		_isNegative
	JMP		_end

_invalidInput:

	; Account for the very smallest possible signed int (-2147483648), which will end up here as a positive number
	CMP		EAX, 2147483648			
	JE		_isValid				; Send the value back up to be added to the array
	
	; Display error message to user, clear registers, and re-prompt
	mDisplayString [EBP + 24]		; reference to error message
	CALL	CrLf
	CALL	CrLf
	MOV		EBX, 0
	MOV		[EDI], EBX
	JMP		_newInput

_isNegative:

	; If string was determined to have a leading -, convert it to a negative and store it
	MOV		EAX, [EDI]
	NEG		EAX
	MOV		[EDI], EAX

_end:
	
	; Restore used resisters
	POP		ESI
	POP		EDI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX

	POP		EBP
	RET		28
ReadVal ENDP


; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a numeric SDWORD value to a string of ASCII digits
; Invokes the mDisplayString macro to print the ASCII representation of the SDWORD value to the output.
; 
; Preconditions: N/A
;
; Postconditions: EAX, EBX, ECX, EDX, EDI, and ESI have the same values before WriteVal was called
;
; Receives: Value being converted to a string and displayed (input, by value)
;           Address where the converted string will be stored (input/output, by reference)
;           The maximum length a user's input may have (input, by value)
;
; Returns: The value is displayed to the user
; ---------------------------------------------------------------------------------
WriteVal PROC
	PUSH    EBP
	MOV     EBP, ESP

	; Save used registers
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	EDI
	PUSH	ESI

	; Get the array that will contain the ASCII characters representing the stirng
	MOV		EDI, [EBP + 12]			; reference to where the string version of the number will be stored
	ADD		EDI, [EBP + 16]			; Go to the end of the offset for the array storing the string

	; Add null byte to the end of the string so it terminates correctly, then decrement EDI to store the next character
	MOV		EAX, 0
	STD	
	STOSB

	; Get the value being converted into a string
	MOV		EAX, [EBP + 8]			; value to be converted

	; Determine if the value is negative
	CMP		EAX, 0
	JL		_isNegative
	PUSH	EBX						; push EBX to preserve stack frame should the number not be negative
	JMP		_getString

_isNegative:
	
	; Store the negative value for later; negate the negative sign if the value is negative
	MOV		EBX, EAX
	PUSH	EBX
	NEG		EAX

_getString:

	; Divide by 10 to get the number in the 1s place of the value
	MOV		EDX, 0
	MOV		EBX, 10
	DIV		EBX

	; Maintain the current value of EAX, as it contains the numbers that still need to be processed
	PUSH	EAX

	; Get the ASCII value for the number currently being assessed
	MOV		EAX, EDX
	ADD		EAX, 48

	; Set the direction flag, put the ASCII value of the number in the array, and decrement EDI
	STD	
	STOSB

	; Restore EAX to the values that still need to be processed
	POP		EAX

	; Determine if there are any values that still need processing
	CMP		EAX, 0
	JNE		_getString

	; Restore the original value and determine if a negative sign needs to be added to the beginning of the string
	POP		EBX
	CMP		EBX, 0
	JL		_addNegativeSign
	JMP		_end

_addNegativeSign:

	; Put the negative sign at the beginning of the string
	PUSH	EAX
	MOV		AL, 45
	STD	
	STOSB
	POP		EAX

_end:
	; Point EDI to the start of the string and display it 
	ADD		EDI, 1					; The last STOSB call put us 1 byte behind where the string starts
	mDisplayString EDI

	; Restore used resisters
	POP		ESI
	POP		EDI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX

	POP		EBP
	RET		12
WriteVal ENDP


; ---------------------------------------------------------------------------------
; Name: DisplayIntegers
;
; Converts each of the numbers provided by the user to a string and displays them to the user
; 
; Preconditions: N/A
;
; Postconditions: EAX, ECX, EDX, EDI, and ESI have the same values before DisplayIntegers was called
;
; Receives: Array containing the numbers provided by the user to be displayed (input, by reference)
;			String to display to the user that the array is about to be printed (input, by reference)
;           The number of values in the array/received by the user being displayed (input, by value)
;			The maximum length a user's input may have (input, by value)
;           Address where each number will be stored for string conversion (input/output, by reference)
;
; Returns: The array is displayed to the user
; ---------------------------------------------------------------------------------
DisplayIntegers PROC
	PUSH    EBP
	MOV     EBP, ESP

	; Save used registers
	PUSH	EAX
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI

	; Display title to user
	mDisplayString [EBP + 12]	

	; Get the array with values and the loop counter
	MOV		ESI, [EBP + 8]			; reference to the offset of the array
	MOV		ECX, [EBP + 16]			; value of NUM_INTS 

	; Loop through the array containing the input values, convert them to strings, and display them
_displayArray:

	PUSH	[EBP + 20]				; value of MAX_LENGTH
	PUSH	[EBP + 24]				; address of the string for conversion
	PUSH	[ESI]					; value being converted to string
	CALL	WriteVal

	; If it's the last value in the array, don't add a comma
	CMP		ECX, 1
	JE		_noComma

	; Separate each number in the array with a comma
	MOV		AL, ","
	CALL	WriteChar
	MOV		AL, " "
	CALL	WriteChar

_noComma:
	; Go to the next value in the array and loop until all values have been displayed
	ADD		ESI, 4
	LOOP	_displayArray

	; Restore used resisters
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EAX

	POP		EBP
	RET		20
DisplayIntegers ENDP


; ---------------------------------------------------------------------------------
; Name: DisplayStats
;
; Calculates the sum and rounded average of the numbers provided by the user, then displays them
; The average is rounded down to the nearest integer
; 
; Preconditions: N/A
;
; Postconditions: EAX, EBX, ECX, EDX, and ESI have the same values before DisplayStats was called
;
; Receives: Array containing the numbers provided by the user to be displayed (input, by reference)
;			String to display to the user that the sum is about to be printed (input, by reference)
;           The number of values in the array/received by the user being displayed (input, by value)
;			The maximum length a user's input may have (input, by value)
;           Address where each number will be stored for string conversion (input/output, by reference)
;           String to display to the user that the average is about to be printed (input, by reference)
;
; Returns: The sum and average of the numbers in the array are calculated and displayed
; ---------------------------------------------------------------------------------
DisplayStats PROC
	PUSH    EBP
	MOV     EBP, ESP

	; Save used registers
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI

	; Dipsplay sum title to user
	mDisplayString [EBP + 12]

	; Clear EAX to hold the sum
	MOV		EAX, 0

	; Get the array with values and the loop counter
	MOV		ESI, [EBP + 8]			; reference to the offset of the array
	MOV		ECX, [EBP + 16]			; value of NUM_INTS 

_sumLoop:

	; Add each value to EAX
	ADD		EAX, [ESI]

	; Go to the next value in the array and loop until all values have been added
	ADD		ESI, 4
	LOOP	_sumLoop

	; Have ESI point to the sum
	MOV		[ESI], EAX

	; Write the value of the sum
	PUSH	[EBP + 20]				; value of MAX_LENGTH
	PUSH	[EBP + 24]				; address of the string for conversion
	PUSH	[ESI]					; value being converted to string
	CALL	WriteVal
	CALL	CrLf

	; Display averqge title to the user
	mDisplayString [EBP + 28]

	; Calculate the average
	MOV		EBX, [EBP + 16]			; value of NUM_INTS 
	CDQ
	IDIV	EBX

	; Have ESI point to the average
	MOV		[ESI], EAX

	; Write the value of the average
	PUSH	[EBP + 20]				; value of MAX_LENGTH
	PUSH	[EBP + 24]				; address of the string for conversion
	PUSH	[ESI]					; value being converted to string
	CALL	WriteVal
	CALL	CrLf

	; Restore used registers
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX

	POP		EBP
	RET		24
DisplayStats ENDP
	
END main
