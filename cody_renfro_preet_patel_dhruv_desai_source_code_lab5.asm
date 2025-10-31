;***********************************************************
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;*	 Author: Cody Renfro and Preet Patel and Dhruv Desai
;*	   Date: 02/20/2025
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register

.def	waitcnt = r17			; Wait Loop Counter *from lab1
.def	ilcnt = r18				; Inner Loop Counter *from lab1
.def	olcnt = r19				; Outer Loop Counter *from lab1
.def	L_counter = r23			; Left whisker count
.def	R_counter = r24			; Right whisker count

.equ	WTime = 100				; Time to wait in wait loop *from lab1

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 5				; Right Engine Enable Bit *from lab1
.equ	EngEnL = 6				; Left Engine Enable Bit *from lab1
.equ	EngDirR = 4				; Right Engine Direction Bit *from lab1
.equ	EngDirL = 7				; Left Engine Direction Bit *from lab1

.equ	MovFwd = (1<<EngDirR|1<<EngDirL); Move Forward Command
.equ	MovBck = $00					; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)	; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used
.org    $0002                   ; INT0 (Right whisker hit)
        rcall   HitRight        ; Right whisker hit interrupt
        reti

.org    $0004                   ; INT1 (Left whisker hit)
        rcall   HitLeft         ; Left whisker hit interrupt
        reti

.org    $0006                   ; INT3 (Clear counters)
        rcall   Clear_Counters   ; Clear counters interrupt
        reti

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize LCD Display
		rcall	LCDInit			; Initializes LCDDriver *from lab3
		rcall	LCDClr			; Clears Screen *from lab3
		rcall	LCDBacklightOn	; Turns on Backlight *from lab3

		;initializing counters
		ldi L_counter, $00
		ldi R_counter, $00

		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge
		ldi mpr, (0<<ISC00) | (1<<ISC01) | (0<<ISC10) | (1<<ISC11)
		sts EICRA, mpr
		ldi mpr, (0<<ISC60) | (1<<ISC61)
		sts EICRB, mpr

		; Configure the External Interrupt Mask
		ldi mpr, (1<<INT0) | (1<<INT1) | (1<<INT3)		; Enabling the interrupts
		out EIMSK, mpr

		ldi mpr, (1<<INTF0) | (1<<INTF1) | (1<<INTF3)	; Load bits to clear INT0, INT1, INT3
		out EIFR, r16  ; Clear interrupt flags

		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		ldi	mpr, MovFwd
		out	PORTB, mpr

		rjmp	MAIN			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the
;	left whisker interrupt, one to handle the right whisker
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:						; *From lab1
		cli
		rcall	LCD_Line2		; Dislpay right hit count
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr

		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd		; Load Move Forward command
		out		PORTB, mpr		; Send command to port

		pop		mpr				; Restore program state
		out		SREG, mpr	
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		
		ldi mpr, (1<<INTF0) | (1<<INTF1) | (1<<INTF3) ; Load bits to clear INT0, INT1, INT3
		out EIFR, mpr  ; Clear interrupt flags
		
		sei
		ret						; Return from subroutine

;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:						; *From lab1
		cli
		rcall	LCD_Line1		; dislpay left hit count
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr			

		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd		; Load Move Forward command
		out		PORTB, mpr		; Send command to port

		pop		mpr				; Restore program state
		out		SREG, mpr	
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		
		ldi mpr, (1<<INTF0) | (1<<INTF1) | (1<<INTF3) ; Load bits to clear INT0, INT1, INT3
		out EIFR, mpr  ; Clear interrupt flags
		
		sei
		ret						; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:							; *From Lab1
		cli
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	
		cli
		ldi		olcnt, 224		; load olcnt register
OLoop:	
		cli
		ldi		ilcnt, 237		; load ilcnt register
ILoop:	
		cli
		dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt			; Decrement wait
		brne	Loop			; Continue Wait loop
		pop		olcnt			; Restore olcnt register
		pop		ilcnt			; Restore ilcnt register
		pop		waitcnt			; Restore wait register
		ldi		mpr, (1<<INTF0) | (1<<INTF1) | (1<<INTF3) ; Load bits to clear INT0, INT1, INT3
		out		EIFR, mpr		; Clear interrupt flags
		ret						; Return from subroutine

;----------------------------------------------------------------
; Sub:	LCD_Line2
; Desc:	Displays the number of times the right whiskers has been 
;		pushed on the LCD
;----------------------------------------------------------------
LCD_Line2:
		cli
		inc R_counter
		ldi XL, $10
		ldi XH, $01
		mov mpr, R_counter
		rcall Bin2ASCII
		rcall LCDWrLn2
		ldi mpr, (1<<INTF0) | (1<<INTF1) | (1<<INTF3) ; Load bits to clear INT0, INT1, INT3
		out EIFR, mpr  ; Clear interrupt flags
		sei
		ret

;----------------------------------------------------------------
; Sub:	LCD_Line1
; Desc:	Displays the number of times the left whiskers has been 
;		pushed on the LCD
;----------------------------------------------------------------
LCD_Line1:
		cli
		inc L_counter
		ldi XL, $00
		ldi XH, $01
		mov mpr, L_counter
		rcall Bin2ASCII
		rcall LCDWrLn1
		ldi mpr, (1<<INTF0) | (1<<INTF1) | (1<<INTF3) ; Load bits to clear INT0, INT1, INT3
		out EIFR, mpr  ; Clear interrupt flags
		sei
		ret

;----------------------------------------------------------------
; Sub:	ClearCounters
; Desc: Clears the left and right counters on the LCD screen
;----------------------------------------------------------------
Clear_Counters:
		ldi R_counter, $00 ;clear right counter
		ldi L_counter, $00 ;clear left counter

		rcall LCDClr ; Clear screen

		ldi mpr, (1<<INTF0) | (1<<INTF1) | (1<<INTF3) ; Load bits to clear INT0, INT1, INT3
		out EIFR, mpr  ; Clear interrupt flags

		ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
