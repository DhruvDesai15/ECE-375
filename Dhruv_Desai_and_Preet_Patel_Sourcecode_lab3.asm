;***********************************************************
;*	This is the skeleton file for Lab 3 of ECE 375
;*
;*	 Author: Preet Patel, Dhruv Desai
;*	   Date: 01/30/2025
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi mpr, LOW(RAMEND)  ; Load the lower byte of RAMEND into mpr  
		out SPL, mpr          ; Store the lower byte in the Stack Pointer Low register 
		ldi mpr, HIGH(RAMEND) ; Load the higher byte of RAMEND into mpr  
		out SPH, mpr          ; Store the higher byte in the Stack Pointer High register 

		; Initialize LCD Display
		call LCDInit

		; NOTE that there is no RET or RJMP from INIT,
		; this is because the next instruction executed is the
		; first instruction of the main program

		;Port D - input
		ldi		mpr, $00	; Set DDRD (Data Direction Register) to input
		out		DDRD, mpr	
		ldi		mpr, $FF	; Enable pull-up resistors on Port D
		out		PORTD, mpr	

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Main function design is up to you. Below is an example to brainstorm.

		; Move strings from Program Memory to Data Memory

		; Display the strings on the LCD Display

		; Read input from Port D
		in		mpr, PIND	
		
		; Check if button on PD4 is pressed
		sbis	PIND, PD4	; Skip next instruction if PD4 is not pressed
		rcall	CLEAR		; Call CLEAR function if PD4 is pressed

		; Check if button on PD5 is pressed
		sbis	PIND, PD5	; Skip next instruction if PD5 is not pressed
		rcall	DISPLAY		; Call DISPLAY function if PD5 is pressed

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:Display Func
; Desc: This function displays strings 
;-----------------------------------------------------------
DISPLAY:
	rcall	CLEAR		; Clear the LCD 

	; Load the starting address of the first string
	ldi		ZL, LOW(STRING_BEG << 1)
	ldi		ZH, HIGH(STRING_BEG << 1)

	; Load the destination address for the first string in data memory
	ldi		YL, $00
	ldi		YH, $01

DHRUV_LOOP:
	lpm     mpr, Z+		; Load character from program memory
	st      Y+, mpr		; Store character in data memory
	cpi		YL, $10		; Check if end of first string is reached
	BRNE    DHRUV_LOOP	; Repeat if not at the end

	; Load the starting address of the second string
	ldi     ZL, LOW(STRING_END << 1)
	ldi     ZH, HIGH(STRING_END << 1)

	; Load the destination address for the second string in data memory
	ldi		YL, $10
	ldi		YH, $01

PREET_LOOP:
	lpm     mpr, Z+		; Load character from program memory
	st      Y+, mpr		; Store character in data memory
	cpi		YL, $20		; Check if end of second string is reached
	BRNE    PREET_LOOP	; Repeat if not at the end

	rcall	LCDWrite	; Display the strings on the LCD
	ret					; Return from function

CLEAR:
	rcall   LCDClr		; Call function to clear the LCD screen
	ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB        "Dhruv           " 	; First string stored in program memory
STRING_END:
.DB        "Preet           " 	; Second string stored in program memory


;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
