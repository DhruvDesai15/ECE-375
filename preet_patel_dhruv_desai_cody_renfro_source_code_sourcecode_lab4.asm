;***********************************************************
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;*	 Author: Preet Patel, Dhruv Desai, Cody Renfro
;*	   Date: 2/12/2025
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine

		; Initialize Stack Pointer

		LDI R16, LOW(RAMEND)	; load low byte of end SRAM address
		OUT SPL, R16			; Write byte to SPL

		LDI R16, HIGH(RAMEND)	; load low byte of end SRAM address
		OUT SPH, R16			; Write byte to SPH

		clr		zero			; Set the zero register to zero, maintain
										; these semantics, meaning, don't
										; load anything else into it.
;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program

		rcall ADD16_OP ; Call function to load ADD16 operands
		nop ; Check load ADD16 operands (Set Break point here #1)

		rcall ADD16; Call ADD16 function to display its results (calculate FCBA + FFFF)
		nop ; Check ADD16 result (Set Break point here #2)

	
		rcall SUB16_OP	; Call function to load SUB16 operands
		nop ; Check load SUB16 operands (Set Break point here #3)
	
		rcall SUB16; Call SUB16 function to display its results (calculate FCB9 - E420)
		nop ; Check SUB16 result (Set Break point here #4)


		rcall MUL24_OP; Call SUB16 function to display its results (calculate FCB9 - E420)
		nop ; Check load MUL24 operands (Set Break point here #5)

		
		rcall MUL24 ; Call MUL24 function to display its results (calculate FFFFFF * FFFFFF)
		nop ; Check MUL24 result (Set Break point here #6)

		
		rcall COMPOUND_OP ; Call the COMPOUND function direct test
		nop ; Check load COMPOUND operands (Set Break point here #7)

		rcall COMPOUND ; Call the COMPOUND function
		nop ; Check COMPOUND result (Set Break point here #8)

DONE:	rjmp	DONE			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;       where the high byte of the result contains the carry
;       out bit.
;-----------------------------------------------------------
ADD16:
		; Load address into X
		ldi		XL, low(ADD16_OP1)	; Load low byte 
		ldi		XH, high(ADD16_OP1)	; Load high byte 

		; Load address into Y
		ldi		YL, low(ADD16_OP2)	; Load low byte 
		ldi		YH, high(ADD16_OP2)	; Load high byte

		; address into Z
        ldi		ZH, HIGH(ADD16_Result) ; Load high byte 
		ldi		ZL, LOW(ADD16_Result)  ; Load low byte

		ld		R16, X+		; X into r16 then incrament 
		ld		R17, X		; X into R17

		ld		R18, Y+		; Y into 18 then Incrament 
		ld		r19, Y		; Y into 19 

		add		R16, R18	; Add registers
		st		Z+, R16		; R16 into Z then incrament 

		adc		R17, R19	; Add with carry
		st		Z+, R17		; R17 into Z then incrament 

		clr		R20
		adc		R20, zero
		st		Z, R20		; R20 into Z 

		ret					; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;       result. Always subtracts from the bigger values.
;-----------------------------------------------------------
SUB16:
		; resukt into X
		ldi		XL, low(SUB16_OP1)	; Load low byte 
		ldi		XH, high(SUB16_OP1)	; Load high 

		; resulkt into Y
		ldi		YL, low(SUB16_OP2)	; Load low byte 
		ldi		YH, high(SUB16_OP2)	; Load high byte 

		; result into Z
		ldi		ZL, low(SUB16_Result)	; Load low byte 
		ldi		ZH, high(SUB16_Result)	; Load high byte 

		ld		R16, X+		; x into r16 then incramnet
		ld		R17, X		; X into R17 then incrament 

		ld		R18, Y+		;  Y into 18 then Incrament
		ld		R19, Y		; Y into 19 

		sub R16, R18 ; Subtract Registers
		st Z+, R16 ;  R16 into Z then increment

		sbc R17, R19 ; Sutract with cary 
		st Z+, R17 ; R17 into Z then increment

		clr		R20         ; Clear R20
		adc		R20, zero   ; Add with carry
		st		Z, R20		; R20 into to Z 

		ret					; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit
;       result.
;-----------------------------------------------------------
MUL24:
;* - Simply adopting MUL16 ideas to MUL24 will not give you steady results. You should come up with different ideas.

		; address into X
		ldi		XL, low(MUL24_OP1)	; Load low byte
		ldi		XH, high(MUL24_OP1)	; Load high byte 

		;  address into Y
		ldi		YL, low(MUL24_OP2)	; Load low byte
		ldi		YH, high(MUL24_OP2)	; Load high byte 

		; address into Z

		ldi		ZH, HIGH(MUL24_Result)
		ldi		ZL, LOW(MUL24_Result)

		ldi		R23, 24		; Load counter into R23

		ld		R16, Y+		; Load Y into R16 then increment
		ld		R17, Y+		; Load Y into R17 then increment
		ld		R18, Y+		; Load Y into R18 then increment

		clr		R19			; Clear R19
		clr		R20			; Clear R20
		clr		R21			; Clear R21

MULTLOOP:
		ror		R21			; Rotate R21
		ror		R20			; Rotate R20
		ror		R19			; Rotate R19
		ror		R18			; Rotate R18
		ror		R17			; Rotate R17
		ror		R16			; Rotate R16

		BRCC	MULTSKIP	; Skip addition if no carry 

		ld		R22, X+		; x into r22 then incrament 
		add		R19, R22	; Add 
		ld		R22, X+		; x into R22 then incrament 
		adc		R20, R22	; Add with carry
		ld		R22, X+		; X into r22 then incrameant 
		adc		R21, R22	; Add  with carry

		ldi		XL, low(MUL24_OP1)	; Load low byte 
		ldi		XH, high(MUL24_OP1)	; Load high byte 

MULTSKIP:
		dec		R23			; Decrement r23
		BRNE	MULTLOOP	; Branch if counter equals 0

		ror		R21			; Rotate R21
		ror		R20			; Rotate R20
		ror		R19			; Rotate R19
		ror		R18			; Rotate R18
		ror		R17			; Rotate R17
		ror		R16			; Rotate R16

		st		Z+, R16		; R16 into z then increment
		st		Z+, R17		; R17 into z then increm
		st		Z+, R18		; R18 into z then increm
		st		Z+, R19		; R19 into z then increm
		st		Z+, R20		; R20 into z then increm
		st		Z+, R21		; R21 into z then increm



		ret						; End a function with RET

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((G - H) + I)^2
;       by making use of SUB16, ADD16, and MUL24.
;
;       D, E, and F are declared in program memory, and must
;       be moved into data memory for use as input operands.
;
;       All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:

		ldi		ZH, HIGH(COMP_OP1)		; Load high byte 
		ldi		ZL, LOW(COMP_OP1)		; Load low byte 

		ld		R16, Z+					; Z into R16 then incrament 
		ld		R17, Z					; z  into R17 

		ldi		ZH, HIGH(SUB16_OP1)		; Load high byte 
		ldi		ZL, LOW(SUB16_OP1)		; Load low byte 

		st		Z+, R16					; incrameant z then R16 into it
		st		Z, R17					; R17 into z

		ldi		ZH, HIGH(COMP_OP2)		; Load high byte 
		ldi		ZL, LOW(COMP_OP2)		; Load low byte 

		ld		R16, Z+					;  Z into R17 then incrament 
		ld		R17, Z					;  z into R17 

		ldi		ZH, HIGH(SUB16_OP2)		; Load high byte 
		ldi		ZL, LOW(SUB16_OP2)		; Load low byte 

		st		Z+, R16					; R16 into z then incrameant 
		st		Z, R17					; R17 into Z

		RCALL	SUB16					;

		; Setup the ADD16 function with SUB16 result and operand F
		; Perform addition next to calculate (D - E) + F

		ldi		ZH, HIGH(SUB16_Result)	; Load high byte 
		ldi		ZL, LOW(SUB16_Result)	; Load low byte 

		ld		R16, Z+					; R16 into Z then incrament 
		ld		R17, Z					; R17 into z

		ldi		ZH, HIGH(ADD16_OP1)		; Load high byte of add operand 1 into Z register
		ldi		ZL, LOW(ADD16_OP1)		; Load low byte of add operand 1 into Z register

		st		Z+, R16					; Store R16 into add operand 1
		st		Z, R17					; Store R17 into add operand 1

		ldi		ZH, HIGH(COMP_OP3)		; Load high byte
		ldi		ZL, LOW(COMP_OP3)		; Load low byte 

		ld		R16, Z+					; z into R16 then incrmeant 
		ld		R17, Z					; z into R17 then incrmeant 

		ldi		ZH, HIGH(ADD16_OP2)		; Load high byte 
		ldi		ZL, LOW(ADD16_OP2)		; Load low byte 

		st		Z+, R16					; R16 into z then incrmeant 
		st		Z, R17					; R17 into z then incremneat 

		RCALL	ADD16					; 

		; Setup the MUL24 function with ADD16 result as both operands
		; Perform multiplication to calculate ((D - E) + F)^2

		ldi		ZH, HIGH(ADD16_Result)	; Load high byte of add 
		ldi		ZL, LOW(ADD16_Result)	; Load low byte of add 

		ld		R16, Z+					; load z inot r16 then incrmeant 
		ld		R17, Z+					; incrmeant z then into R17
		ld		R18, Z					; z into R18 
										
		ldi		ZH, HIGH(MUL24_OP1)		; Load high byte 
		ldi		ZL, LOW(MUL24_OP1)		; Load low byte 
										
		st		Z+, R16					; R16 into z then incrmeant 
		st		Z+, R17					; R17 into z then incrmeant 
		st		Z,  R18					; SR18 into z
										
		ldi		ZH, HIGH(MUL24_OP2)		; Load high byte
		ldi		ZL, LOW(MUL24_OP2)		; Load low byte 
										
		st		Z+, R16					; R16 into z then incrmeant 
		st		Z+, R17					;R17 into z then incrmeant 
		st		Z,	R18					;R18 into z

		RCALL	MUL24					;

		ldi		ZH, HIGH(MUL24_Result)	; Load high byte 
		ldi		ZL, LOW(MUL24_Result)	; Load low byte 

		ld		R16, Z+					; Load R16 from add result
		ld		R17, Z+					; Load R17 from add result
		ld		R18, Z+					; Load R18 from add result
		ld		R19, Z+					; Load R16 from add result
		ld		R20, Z+					; Load R17 from add result
		ld		R21, Z					; Load R18 from add result

		ldi		ZH, HIGH(COMP_Result)	; Load high byte of mul operand 1 into Z register
		ldi		ZL, LOW(COMP_Result)	; Load low byte of mul operand 1 into Z register

		st		Z+, R16					; R 16 into z then incrmenant 
		st		Z+, R17					; R 16 into z then incrmenant
		st		Z+,	R18					; R 16 into z then incrmenant
		st		Z+, R19					; R 16 into z then incrmenant
		st		Z+, R20					; R 16 into z then incrmenant
		st		Z,	R21					; R 16 into z then incrmenant

		ret								; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;       A - Operand A is gathered from address $0101:$0100
;       B - Operand B is gathered from address $0103:$0102
;       Res - Result is stored in address
;             $0107:$0106:$0105:$0104
;       You will need to make sure that Res is cleared before
;       calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: ADD16_OP
; Desc: Moves values OperandA and OperandB in program memory
;       to data memory where ADD16 will get its inputs from
;-----------------------------------------------------------
ADD16_OP:								; Begin a function with a label
		ldi		ZH, HIGH(OperandA << 1)	; Load high byte of operand A into high byte of Z register
		ldi		ZL, LOW(OperandA << 1)	; Load low byte of operand A into high byte of register
		lpm		R16, Z+					; Load Z register to R16 and increment
		lpm		R17, Z					; Load Z register to R17

		ldi		ZH, HIGH(OperandB << 1)	; Load high byte of operand B into high byte of Z register
		ldi		ZL, LOW(OperandB << 1)	; Load low byte of operand B into high byte of Z register
		lpm		R18, Z+					; Load Z register to R18 and increment
		lpm		R19, Z					; Load Z register to R17

		; Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)		; Load low byte of OP1 address
		ldi		XH, high(ADD16_OP1)		; Load high byte of OP1 address

		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)		; Load low byte of OP2 address
		ldi		YH, high(ADD16_OP2)		; Load high byte of OP2 address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(ADD16_Result)	; Load high byte of Result into high byte of register
		ldi		ZL, LOW(ADD16_Result)	; Load low byte of Result into high byte of register

		st		X+, R16					; Store R16 into where X points with post increment
		st		X, R17					; Store R17 into where X points
		st		Y+, R18					; Store R18 into where Y points with post increment
		st		Y, R19 					; Store R19 into where Y points

		ret								; End a function with RET
;-----------------------------------------------------------
; Func: SUB16_OP
; Desc: Moves values OperandC and OperandD in program memory
;       to data memory where SUB16 will get its inputs from
;-----------------------------------------------------------
SUB16_OP:								; Begin a function with a label
		ldi		ZH, HIGH(OperandC << 1)	; Load high byte of operand C into high byte of Z register	
		ldi		ZL, LOW(OperandC << 1)	; Load low byte of operand C into high byte of Z register	
		lpm		R16, Z+					; Load Z register to R16 and increment
		lpm		R17, Z					; Load Z register to R17

		ldi		ZH, HIGH(OperandD << 1)	; Load high byte of operand D into high byte of Z register	
		ldi		ZL, LOW(OperandD << 1)	; Load low byte of operand D into high byte of Z register	
		lpm		R18, Z+					; Load Z register to R18 and increment
		lpm		R19, Z					; Load Z register to R17

		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP1)	    ; Load low byte of OP1 address
		ldi		XH, high(SUB16_OP1)	    ; Load high byte of OP1 address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)	    ; Load low byte of OP2 address
		ldi		YH, high(SUB16_OP2)	    ; Load high byte of OP2 address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(SUB16_Result)	; Load high byte of Result operand into high byte of Z register
		ldi		ZL, LOW(SUB16_Result)	; Load low byte of Result operand into high byte of Z register
										
		st		X+, R16					; Store R16 into where X points with post increment
		st		X, R17					; Store R17 into where X points
		st		Y+, R18					; Store R18 into where Y points with post increment
		st		Y, R19					; Store R19 into where Y points

		ret								; End a function with RET

;-----------------------------------------------------------
; Func: MUL24_OP
; Desc: Moves values OperandE1, OperandE2, OperandF1, and
;       OperandF2 in program memory to data memory where
;		MUL24 will get its inputs from
;-----------------------------------------------------------
MUL24_OP:									; Begin a function with a label
		ldi		ZH, HIGH(OperandE1 << 1)	; Load high byte 
		ldi		ZL, LOW(OperandE1 << 1)	;	Load low byte	
		lpm		R16, Z+					; incrmeant Z then into R16
		lpm		R17, Z					;  Z into R16

		ldi		ZH, LOW(OperandE2 << 1)	; Load high byte 
		lpm		R18, Z					; z into r 18 


									  
		ldi		ZH, HIGH(OperandF1 << 1)	; Load high byte 
		ldi		ZL, LOW(OperandF1 << 1)	; Load low byte 	
		lpm		R19, Z+					; Z then into R19 then incrmenat 
		lpm		R20, Z					; Z then into R16

		ldi		ZL, LOW(OperandF2 << 1)	; Load low byte	
		lpm		R21, Z					;z into r21 

		; Load beginning address of first operand into X
		ldi		XL, low(MUL24_OP1)		; low byte of address
		ldi		XH, high(MUL24_OP1)		;high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(MUL24_OP2)		;low byte of address
		ldi		YH, high(MUL24_OP2)		;  high byte of address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(MUL24_Result)	; Load high byte
		ldi		ZL, LOW(MUL24_Result)	; Load low byte

		st		X+, R16					;  R16 into  X then increment
		st		X+, R17					; R16 into  X then increment
		st		X+, R18					; R18 into  X then increment
		st		Y+, R19					; R16 into  y then increment
		st		Y+, R20					; R16 into  y then increment
		st		Y+, R21					; R16 into  y then increment

		ret								; End a function with RET


;-----------------------------------------------------------
; Func: COMPOUND_OP
; Desc: Cut and paste this and fill in the info at the
;       beginning of your functions
;-----------------------------------------------------------
COMPOUND_OP:							; Begin a function with a label
		ldi		ZH, HIGH(OperandG << 1)	; Load high byte of operand D into Z register
		ldi		ZL, LOW(OperandG << 1)	; Load low byte of operand D into Z register

		lpm		R16, Z+					; Load R16 from operand D
		lpm		R17, Z					; Load R17 from operand D

		ldi		ZH, HIGH(COMP_OP1)		; Load high byte of sub operand 1 into Z register
		ldi		ZL, LOW(COMP_OP1)		; Load low byte of sub operand 1 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		ldi		ZH, HIGH(OperandH << 1)	; Load high byte of operand E into Z register
		ldi		ZL, LOW(OperandH << 1)	; Load low byte of operand E into Z register

		lpm		R16, Z+					; Load R16 from operand E
		lpm		R17, Z					; Load R17 from operand E

		ldi		ZH, HIGH(COMP_OP2)		; Load high byte of sub operand 2 into Z register
		ldi		ZL, LOW(COMP_OP2)		; Load low byte of sub operand 2 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		ldi		ZH, HIGH(OperandI << 1)	; Load high byte of operand F into Z register
		ldi		ZL, LOW(OperandI << 1)	; Load low byte of operand F into Z register

		lpm		R16, Z+					; Load R16 from operand F
		lpm		R17, Z					; Load R17 from operand F

		ldi		ZH, HIGH(COMP_OP3)		; Load high byte of add operand 2 into Z register
		ldi		ZL, LOW(COMP_OP3)		; Load low byte of add operand 2 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		ret								; End a function with RET


;***********************************************************
;*	Stored Program Data
;*	Do not  section.
;***********************************************************
; ADD16 operands
OperandA:
	.DW 0xFCBA
OperandB:
	.DW 0xFFFF

; SUB16 operands
OperandC:
	.DW 0XFCB9
OperandD:
	.DW 0XE420

; MUL24 operands
OperandE1:
	.DW	0XFFFF
OperandE2:
	.DW	0X00FF
OperandF1:
	.DW	0XFFFF
OperandF2:
	.DW	0X00FF

; Compoud operands
OperandG:
	.DW	0xFCBA				; test value for operand G
OperandH:
	.DW	0x2022				; test value for operand H
OperandI:
	.DW	0x21BB				; test value for operand I

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 4

; Below is an example of data memory allocation for ADD16.
; Consider using something similar for SUB16 and MUL24.
.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0120				; data memory allocation for results
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

.org	$0130				; data memory allocation for operands
SUB16_OP1:
		.byte 2				; allocate two bytes for first operand of SUB16
SUB16_OP2:
		.byte 2				; allocate two bytes for second operand of SUB16

.org	$0140				; data memory allocation for results
SUB16_Result:
		.byte 2				; allocate two bytes for SUB16 result

.org	$0150				; data memory allocation for operands
MUL24_OP1:
		.byte 3				; allocate three bytes for first operand of MUL24
MUL24_OP2:
		.byte 3				; allocate three bytes for second operand of MUL24

.org	$0160				; data memory allocation for results
MUL24_Result:
		.byte 6				; allocate six bytes for MUL24 result

.org	$0170				; data memory allocation for operands
COMP_OP1:
		.byte 2				; allocate three bytes for first operand of COMP
COMP_OP2:
		.byte 2				; allocate three bytes for second operand of COMP
COMP_OP3:
		.byte 2				; allocate three bytes for third operand of COMP

.org	$0180				; data memory allocation for results
COMP_Result:
		.byte 6				; allocate six bytes for MUL24 result



