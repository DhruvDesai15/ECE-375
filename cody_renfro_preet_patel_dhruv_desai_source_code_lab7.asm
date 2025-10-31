;***********************************************************
;*
;*????This is the TRANSMIT skeleton file for Lab 7 of ECE 375
;*
;*  ??Rock Paper Scissors
;* ???Requirement:
;* ???1. USART1 communication
;* ???2. Timer/counter1 Normal mode to create a 1.5-sec delay
;***********************************************************
;*
;*???? Author: Cody Renfro and Preet Patel and Dhruv Desai
;*???? Date: 3/12/2025
;*
;***********************************************************

.include "m32U4def.inc"         ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multi-Purpose Register
.def    tx = r23                ; Transmit register
.def    rx = r24                ; Receive register
.def    counter = r17           ; General-purpose counter
.def	waitcnt = r25			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

; Use this signal code between two boards for their game ready
.equ    SendReady = 0b11111111

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org    $0000                   ; Beginning of IVs
	    rjmp    INIT            ; Reset interrupt

.org    $0002					; INT0
		rcall   CHOICE          ; Call CHOICE function 
		reti                       

.org    $0032                   ; USART1 Receive Complete Interrupt Vector
		rcall   receive         ; Call RX function 
		reti                       

.org    $0056                   ; End of Interrupt Vectors


;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:

	; Initialize Stack Pointer
	ldi		mpr, low(RAMEND)
	out		SPL, mpr		; Load SPL with low byte of RAMEND
	ldi		mpr, high(RAMEND)
	out		SPH, mpr		; Load SPH with high byte of RAMEND

	; Initialize LCD
    rcall LCDINIT            ; Call LCD initialization routine
    rcall LCDClr             ; Clear the LCD screen
    rcall LCDBacklightOn     ; Turn on the LCD backlight

    ; I/O Ports
    ldi mpr, 0b00001000      ; Set PD3 (TXD1) as output, PD2 (RXD1) as input
    out DDRD, mpr            ; for output
    ldi mpr, $00             ; Initialize Port D Data Register
    out DDRD, mpr            ; for output
    
	ldi mpr, 0b10010000      ; pull up resistors pd7 and pd4
    out PORTD, mpr            
    ldi mpr, 0b11111111      ; port B output, leds
    out DDRB, mpr             
    ldi mpr, 0b00000000      ; set port b outputs to 0 
    out PORTB, mpr           ;?

    ldi mpr, high(416)       ; Load high byte of baud rate (16Mz/(16*2400) )- 1 = 416
    sts UBRR1H, mpr           
    ldi mpr, low(416)        ; Load low byte baudrate
    sts UBRR1L, mpr           

    ldi mpr, 0b10011000      ; Enable receiver and transmitter
    sts UCSR1B, mpr           

    ldi mpr, 0b00001110      ; Set frame format: 8 data bits, 2 stop bits
    sts UCSR1C, mpr           


    ;TIMER/COUNTER1
    ldi mpr, 0b00000000      ; Normal mode
    sts TCCR1A, mpr           
    ldi mpr, 0b00000101      ; Set prescaler to 1024 
    sts TCCR1B, mpr          

        ; External Interrupts
    ldi mpr, 0b00000010      ; Configure falling edge for INT0 interrupt
    sts EICRA, mpr           ; Set interrupt control register EICRA


    sei                      ; Enable global interrupts


;***********************************************************
;*  Main Program
;***********************************************************
MAIN:
 
    rcall DISPLAY_WELCOME           

    ; Poll for input on PD7
    in mpr, PIND             ; Read value of Port D 
    andi mpr, 0b10000000     ; Mask  PD7
    cpi mpr, 0b10000000      ; Compare to see if pressed 
    breq MAIN                

    
    rcall LCDClr             ; Clear the LCD screen
    
    rcall READY              ; display ready 

    rcall LCDClr             
    
    rcall RPS                ; Start the game

    rjmp MAIN               

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Sub: DISPLAY_WELCOME
; Desc: Subroutine that displays the welcome message to
;		both of the boards and waiting for each board to
;		press PD7.
;-----------------------------------------------------------
DISPLAY_WELCOME:

    ldi ZL, low(WELCOME_MESSAGE<<1)		; load message 
    ldi ZH, high(WELCOME_MESSAGE<<1)	;load message
    rcall ALLIGN1						; Align first line of lcd 
    rcall Write							; display message 

    ldi ZL, low(PLEASE_MESSAGE<<1)  
    ldi ZH, high(PLEASE_MESSAGE<<1) 
    rcall ALLIGN2						; Align to 2nd line of lcd 
    rcall Write                    

    ret                            

;-----------------------------------------------------------
; Func: Transmit
; Desc: Checks if the USART transmitter is ready and sends 
;       data from the transmit buffer.
;-----------------------------------------------------------
Transmit:
    lds mpr, UCSR1A          ; Load USART status register into mpr
    sbrs mpr, UDRE1          ; make sure it sent otherwise skip next instruction
    rjmp Transmit            ; Go until transmiter ready

    sts UDR1, tx             ; transmit date from TX
    ret                     

;-----------------------------------------------------------
; Func: receive
; Desc: Subroutine that stores data from
;	UDR1 to rxdata register.
;-----------------------------------------------------------
receive:
    clr rx					; Clear rx 
    lds rx, UDR1			; Load transmited value 
    ret                   

;-----------------------------------------------------------
; Func: LEDCOUNTER
; Desc: Turns on LEDs (PB7-4) then in intervals 
; 	of 1.5 seconds turn off the LEDs.
;-----------------------------------------------------------
LEDCOUNTER:

	ldi mpr, 0b11110000		; all lights on
	out PORTB, mpr

	rcall WAIT_1_5sec		;turn off every 1.5 seconds 
	cbi PORTB, PB7
	rcall WAIT_1_5sec
	cbi PORTB, PB6
	rcall WAIT_1_5sec
	cbi PORTB, PB5
	rcall WAIT_1_5sec
	cbi PORTB, PB4

	ret

;-----------------------------------------------------------
; Func: RPS
; Desc: Handles the Rock, Paper, Scissors game logic, including:
;       - Displaying game start message
;       - Initiating LED countdown
;       - Transmitting and receiving player choices
;       - Determining and displaying the winner
;-----------------------------------------------------------
RPS:
    push YH							; Save yh
    push YL							; Save yl
    push ZH                  
    push ZL                   

    clr rx							; clear for start
    clr tx							; clear for start 

									; Configure the External Interrupt Mask
    ldi mpr, (1 << INT0)			; enabiling the interupts 
    out EIMSK, mpr          

									;start message 
    rcall LCDClr             
    ldi ZL, low(GAME_MESSAGE<<1) 
    ldi ZH, high(GAME_MESSAGE<<1)
    rcall ALLIGN1					; allign to first line lcd
    rcall Write						; write message 

    rcall LEDCOUNTER				; countdown
    
    ldi mpr, 0b00000000				; disable after choice 
    out EIMSK, mpr           

	rcall WAIT_1_5sec       

    rcall Transmit					; send choice to other screen

    rcall WAIT_1_5sec        

									; other players choice 
    cpi rx, 0						; Compare rx with rock 
    brne OutputPaper				; if not 0 got to DisplayPaper Function
    ldi ZL, low(ROCK_MESSAGE<<1)	; otherwise load message 
    ldi ZH, high(ROCK_MESSAGE<<1)
    rcall ALLIGN1					; Align to first line 

	
	ldi r20, $10					; load with value of 16 

									; Move strings from Program Memory to Data Memory
	LOOPLOAD1: 
		lpm r7, Z+					;load from prgram memorey to r7
		st Y+, r7					; store r7 into data memorey 
		dec r20
		brne LOOPLOAD1				; keep going until r20 is 0

		rcall LCDWrLn1
		rjmp CheckWinner			; Jump to CheckWinner to proceed

OutputPaper:
    cpi rx, 1						; Compare rx with paper
    brne OutputScissors				; if not one go to OutputScissors
    ldi ZL, low(PAPER_MESSAGE<<1)	; load message
    ldi ZH, high(PAPER_MESSAGE<<1)
    rcall ALLIGN1					; Alignfirst line
    rcall Write						; Write message 
    rjmp CheckWinner          

OutputScissors:
    cpi rx, 2							; Compare rx with Scissors
    brne CheckWinner					; if not 2 go to checkwinner 
    ldi ZL, low(SCISSORS_MESSAGE<<1)	; Load message 
    ldi ZH, high(SCISSORS_MESSAGE<<1)
    rcall ALLIGN1						; Alignfirst line
    rcall Write							; Write message

CheckWinner:
    rcall WAIT_1_5sec					; wait so player can see choices 
    rcall WAIT_1_5sec        

    rcall WINNER						; determine and display the winner

    pop ZL                   
    pop ZH                   
    pop YL                  
    pop YH                   

    ret                      
;-----------------------------------------------------------
; Func: Write
; Desc: Moves from the program memory 
;        into the data memory for LCD display.
;-----------------------------------------------------------

Write:
	push mpr           
    push counter           
    in mpr, SREG            
    push mpr           
    push ZL					;save the Z pointer              
    push ZH          
    push YL					; Save Y pointer          
    push YH                 

    ldi counter, $00        ; set counter to 0 
    rcall Move              ; copy from program to data memorey 
    rcall LCDWrite          ; display data 

    pop YH					; go back to the values we saved earlier                 
    pop YL               
    pop ZH               
    pop ZL                
    pop mpr               
    out SREG, mpr        
    pop counter            
    pop mpr          

    ret        
        
Move:                     
	; move bytes from program memory to data memory
   inc counter          
   lpm mpr, Z+            
   st Y+, mpr             
   cpi counter, $10       
   brne Move             
   ret    
	
	 
;-----------------------------------------------------------
; Func: ALLIGN1
; Desc: Sets Y pointer to align the cursor to the first line 
;       of the LCD.
;-----------------------------------------------------------	               
ALLIGN1:                   
						   ;first line of the LCD
    ldi YL, $00            ; Load low byte
    ldi YH, $01            ; Load the high byte 
    ret                    

;-----------------------------------------------------------
; Func: ALLIGN2
; Desc: Sets Y pointer to align the cursor to the second line 
;       of the LCD.
;-----------------------------------------------------------
ALLIGN2:                  
						   ;second line of lcd 
    ldi YL, $10            ; Load the low byte
    ldi YH, $01            ; Load the high byte 
    ret                    

;-----------------------------------------------------------
; Func: READY
; Desc: Displays Ready messages on the LCD and synchronizes 
;       communication between connected devices.
;-----------------------------------------------------------
READY:
    push YH                  
    push YL                  
    push ZH                  
    push ZL                   

    
    ldi ZL, low(READY_MESSAGE<<1)	; load the read message  
    ldi ZH, high(READY_MESSAGE<<1)    
	rcall ALLIGN1					; Align first line 
    rcall Write						; write message to screen

    
    ldi ZL, low(READY_MESSAGE2<<1)  
    ldi ZH, high(READY_MESSAGE2<<1) 
    rcall ALLIGN2					; Align second line 
    rcall Write						; Write message to screen

SEND:
   ldi tx, SendReady				; Load SendReady into transmit
   rcall Transmit					; Transmit the value in tx

   cpi rx, 0b11111111				; check if other player read 
   brne SEND						; Otherwise do process again 

   pop ZL                   
   pop ZH                   
   pop YL                   
   pop YH                   

   ret                      

;-----------------------------------------------------------
; Func: CHOICE
; Desc: Goes through the Rock, Paper, and 
;       Scissors choices, displays the current choice 
;       on the screen.
;-----------------------------------------------------------
CHOICE:
    inc tx                ; incrament current choice 
    cpi tx, $03           ; Check if the TX is 3 or more out of range
    brge ROCK			  ; If tx >= 3, Then go back to ROCK to reset to Rock 

;-----------------------------------------------------------
; Func: CHOOSECHOICE
; Desc: DEtermines which choice to display on screen
;-----------------------------------------------------------
CHOOSECHOICE:
    cpi tx, $01           ; Compare tx with 1 Paper
	breq PAPER            ; If TX is equal to 1, then go to PAPER
    rjmp SCISSORS         ; and If tx is not equal to 1, then go to SCISSORS

;-----------------------------------------------------------
; Func: DISPLAYCHOICE
; Desc: Display the choice on the screen
;-----------------------------------------------------------
DISPLAYCHOICE:
	
	ldi YL, $10			; put to 2nd line of lcd 
	ldi YH, $01

	ldi r20, $10	
	LOOPLOAD2: 
		lpm r7, Z+		; same logic as earlier 
		st Y+, r7 
		dec r20
		brne LOOPLOAD2

	rcall LCDWrLn2
    ldi waitcnt, 10           
    rcall Wait                
    
	ldi mpr, 0b00001011	 ; clear interupt so button can be pressed again       
    out EIFR, mpr             
	ret                       

ROCK:
    ldi tx, $00						; Reset tx to Rock
    ldi ZL, low(ROCK_MESSAGE<<1)	;load message
    ldi ZH, high(ROCK_MESSAGE<<1)	;load message
    rjmp DISPLAYCHOICE				; display choice 

PAPER:
    ldi ZL, low(PAPER_MESSAGE<<1)	; Load message
    ldi ZH, high(PAPER_MESSAGE<<1)	; Load message 
    rjmp DISPLAYCHOICE				; display choice 

SCISSORS:
    ldi ZL, low(SCISSORS_MESSAGE<<1)	; Load message
    ldi ZH, high(SCISSORS_MESSAGE<<1)	; load message
    rjmp DISPLAYCHOICE					; display choice 

;-----------------------------------------------------------
; Function: WINNER
; Description: Determines the winner of the game by comparing player choices 
;              Displays the game result  on the LCD screen. 
;-----------------------------------------------------------
WINNER:
    push mpr                  

    cp tx, rx						; compare choices 
    brne WINCOMP					; go to wincomp to get winner 
									; If a draw 
    ldi ZL, low(DRAW_MESSAGE<<1)	; load message
    ldi ZH, high(DRAW_MESSAGE<<1)	; load message
    rjmp WINWRITE					; display message 

;-----------------------------------------------------------
; Function: WINCOMP
; Description: Prepares to determine the winner by checking 
;              if the player's choice needs to be adjusted 
;              for the comparison.
;-----------------------------------------------------------
WINCOMP:
    mov mpr, tx						; copy choice then move to mpr
    inc mpr							; Increment mpr to check the next case
    cpi mpr, $03					; check for rock paper scissors 
    brge CHECK						; greater than or equal to 3 then go to CHECK

;-----------------------------------------------------------
; Function: NOTWINNER
; Description:Checks if the player looses by comparing 
;			  choices
;-----------------------------------------------------------
NOTWINNER:
    cp mpr, rx						; compare player choices 
    brne WIN						; if not same go to WIN
    ldi ZL, low(LOST_MESSAGE<<1)	; load message 
    ldi ZH, high(LOST_MESSAGE<<1)	; load message 
    rjmp WINWRITE					; display the lost message 

;-----------------------------------------------------------
; Function: WINWRITE
; Description: Displays the final result 
;              on the LCD and waits to allow the player 
;              to see the outcome.
;-----------------------------------------------------------
WINWRITE:
    rcall ALLIGN1					; Align first line 
    rcall Write						; Write the string 
    
    rcall WAIT_1_5sec				; wait to see results 
    rcall WAIT_1_5sec         
    ret                      

;-----------------------------------------------------------
; Function: WIN
; Description: If the player wins, this function loads the 
;              appropriate message and calls WINWRITE to 
;              display it.
;-----------------------------------------------------------
WIN:
    ldi ZL, low(WON_MESSAGE<<1)		; load message 
    ldi ZH, high(WON_MESSAGE<<1)	; load message 
    rjmp WINWRITE					; display the won message

;-----------------------------------------------------------
; Function: CHECK
; Description: Handles the wrap-around case for Rock-Paper-Scissors 
;              comparison. If the player's choice was out of range, 
;              it resets and jumps back to NOTWINNER.
;-----------------------------------------------------------
CHECK:
    ldi mpr, $00					; set to 0 if 3 or higher 
    rjmp NOTWINNER					; Jump back to NOTWINNER to re-evaluate with the reset mpr

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
;-----------------------------------------------------------
; Function: WAIT_1_5sec
; Description: Introduces a delay of approximately 1.5 seconds 
;              by utilizing Timer/Counter1 in normal mode.
;-----------------------------------------------------------
WAIT_1_5sec:
   
    ldi     r18, high(53816)   ; load and store high byte - 1.5 sec
    sts     TCNT1H, r18         

    ldi     r18, low(53816)    ; load and store low byte - 1.5 sec
    sts     TCNT1L, r18         

TIME_LOOP:
 
    SBIS    TIFR1, TOV1        ; Skip the next instruction if timer overflow flag is not set
    rjmp    TIME_LOOP          ; if not set loop back 

    sbi     TIFR1, TOV1        ; Set the TOV1 bit in TIFR1 to clear the overflow flag
    ret                        

;***********************************************************
;*	Stored Program Data
;***********************************************************
;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
WELCOME_MESSAGE:
.DB "Welcome!        "

PLEASE_MESSAGE:
.DB "Please press PD7"

READY_MESSAGE:
.DB "Ready. Waiting  "

READY_MESSAGE2:
.DB "for the opponent"

GAME_MESSAGE:
.DB "Game start!     "

ROCK_MESSAGE:
.DB "Rock            "

PAPER_MESSAGE:
.DB "Paper           "

SCISSORS_MESSAGE:
.DB "Scissors        "

LOST_MESSAGE:
.DB "You lost!       "

WON_MESSAGE:
.DB "You Won!        "

DRAW_MESSAGE:
.DB "DRAW!           "

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver











