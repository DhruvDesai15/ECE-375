;***********************************************************
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;*	 Author: Cody Renfro and Preet Patel and Dhruv Desai
;*	   Date: 02/27/2025
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	pwminc = r20			; increment pwm speed
.def	spdlevel = r21			; Speed level output to leds

.equ	WTime = 25				; Time to wait in wait loop

.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit
.equ	OCR1A = 0x88			; Output Compare Register 1A
.equ	OCR1B = 0x8A			; Output Compare Register 1B

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000				; Beginning of IVs
		rjmp INIT			; Reset interrupt

; place instructions in interrupt vectors here, if needed

.org	$0002
		rcall IncSpeed		; Call IncSpeed function
		reti

.org	$0004
		rcall DecSpeed		; Call DecSpeed function
		reti


.org	$0008
		rcall MaxSpeed		; Call MaxSpeed function
		reti

.org	$0056				; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer

		ldi mpr, HIGH(RAMEND)			; Load high byte of RAM end address into mpr
		out SPH, mpr					; Set Sph byte
		ldi mpr, LOW(RAMEND)			; Load low byte of RAM end address into mpr
		out SPL, mpr					; Set Spl byte

		; Configure I/O ports

		ldi		mpr, $FF	
		out		DDRB, mpr				; Set Port B Data Direction Register for output
		ldi		mpr, $00				; Initialize Port B Data Register
		out		PORTB, mpr				; so all Port B outputs are low

		sbi		DDRB, PB6				; Initialize led 6 for pwm
		sbi		DDRB, PB5				; Initialize led 5 for pwm

		; Initialize Port D for input

		ldi		mpr, $00				; Set Port D Data Direction Register
		out		DDRD, mpr				; for input
		ldi		mpr, $FF				; Initialize Port D Data Register
		out		PORTD, mpr				; so all Port D inputs are Tri-State

		; Configure External Interrupts, if needed

		ldi 	mpr, (1<<ISC31)|(1<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00)
		sts 	EICRA, mpr				; Set interupts to falling edge

		ldi		mpr, (1<< INT3)|(1<< INT1)|(1<<INT0)
		out 	EIMSK, mpr				; Enable ports 0,1,3 for interupts

										; Configure 16-bit Timer/Counter 1A and 1B
										; Fast PWM, 8-bit mode, no prescaling

		ldi 	mpr, (1<<COM1A1)|(1<<COM1A0)|(1<<COM1B1)|(1<<COM1B0)|(1<<WGM10)	; Set com to inverting
		sts		TCCR1A, mpr				; and set wgm for fast pwm 8 bit

		ldi 	mpr, (1<<WGM12)|(1<<CS10); Set cs for no prescaling
		sts		TCCR1B, mpr				; and set wgm for fast pwm 8 bit

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL) on Port B

		ldi		spdlevel, 0b10011111	; Set leds to initially be full speed and on
		out		PORTB, spdlevel

										; Set initial speed, display on Port B pins 3:0

		ldi		pwminc, 0x11			; set increment about for 16 different speed levels

		ldi		mpr, 0xFF				; set initial pwm brightness for
		sts		OCR1A, mpr				; full initial speed
		sts		OCR1B, mpr



		; Enable global interrupts (if any are used)

		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;----------------------------------------------------------------
; Sub:	IncSpeed
; Desc:	increments speed counter and decreases pwm for LED 5 and
;		6 then updates output to leds
;----------------------------------------------------------------
IncSpeed:

		
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr

		ldi		waitcnt, WTime	; Wait
		rcall	Wait			; Call wait function

		lds		mpr, OCR1A		; load pwm intensity
		cpi		mpr, 0xFF		; if intensity is off then skip
		breq	SKIP_UP	

		add		mpr, pwminc		; decrease intensity of pwm
		inc		spdlevel		; increment speed counter

		sts		OCR1A, mpr		; set pwm intensity
		sts		OCR1B, mpr
		out		PORTB, spdlevel	; output speed counter and tekbot leds

SKIP_UP:	
		ldi		mpr, $0B		; Load 1 for each INT used into mpr
		out		EIFR, mpr		; Clear interupts for each INT used

		pop		mpr				; Restore program state
		out		SREG, mpr
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr

		ret						; Return

;----------------------------------------------------------------
; Sub:	DecSpeed
; Desc:	decrements speed counter and increases pwm for LED 5 and
;		6 then updates output to leds
;----------------------------------------------------------------
DecSpeed:
		
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr

		ldi		waitcnt, WTime	; Wait
		rcall	Wait			; Call wait function

		lds		mpr, OCR1A		; load pwm intensity
		cpi		mpr, 0x00		; if intensity is max then skip
		breq	SKIP_DOWN
			
		sub		mpr, pwminc		; increase intensity of pwm
		dec		spdlevel		; decrement speed counter

		sts		OCR1A, mpr		; set pwm intensity
		sts		OCR1B, mpr
		out		PORTB, spdlevel	; output speed counter and tekbot leds

SKIP_DOWN:

		ldi		mpr, $0B		; Load 1 for each INT used into mpr
		out		EIFR, mpr		; Clear interupts for each INT used
		
		pop		mpr				; Restore program state
		out		SREG, mpr
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr

		ret						; Return


;----------------------------------------------------------------
; Sub:	MaxSpeed
; Desc:	maxes speed counter and zeros out pwm for leds
;		then updates output and values accordingly
;----------------------------------------------------------------

MaxSpeed:
		
		push	mpr						; Save mpr register
		push	waitcnt					; Save wait register
		in		mpr, SREG				; Save program state
		push	mpr

		ldi		waitcnt, WTime			; Wait
		rcall	Wait					; Call wait function

		ldi		spdlevel, 0b10011111	; set leds to max, speed counter and motors enabled
		ldi		mpr, 0xFF				; set pwm to 0
		
		sts		OCR1A, mpr				; store pwm for led output
		sts		OCR1B, mpr	
		out		PORTB, spdlevel			; output led for speed counter and motor enable

		ldi		mpr, $0B				; Load 1 for each INT used into mpr
		out		EIFR, mpr				; Clear interupts for each INT used

		pop		mpr						; Restore program state
		out		SREG, mpr
		pop		waitcnt					; Restore wait register
		pop		mpr						; Restore mpr

		ret								; Return
;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------

Wait:
		push	waitcnt		; Save wait register
		push	ilcnt		; Save ilcnt register
		push	olcnt		; Save olcnt register

Loop:	ldi		olcnt, 224	; load olcnt register
OLoop:	ldi		ilcnt, 237	; load ilcnt register
ILoop:	dec		ilcnt		; decrement ilcnt
		brne	ILoop		; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop		; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop		; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret					; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program
