; uart routines
; These are routines connected with the 16C550 uart.
ROM_DIS_CK	equ  $38    ;== Decode_7

; port_numbers.asm

; Here are the port numbers for various UART registers:
uart_tx_rx 		equ    	8
uart_IER 		equ    	9
uart_ISR 		equ     10  ; Also known as FCR
uart_LCR 		equ     11
uart_MCR 		equ     12  ; modem control reg
uart_LSR 		equ     13
uart_MSR 		equ     14
uart_scratch 	equ     15

; Initialises the 16c550c UART for input/output
configure_uart:
	; Configure the UART 16550 after a reset.
	; For the sake of definitely getting the job done, let's pause here for ages before doing it.
	; Without this pause the Z80 can get started before the UART is ready.
	; Don't ask me how I know this.
	;
	; Pass in the required BAUD rate divisor in b.
	; Pass in the required hardware flow control in c.
	push bc
	call medium_pause
	pop bc

    ld a,80H                        ; Go into "Divisor Latch Setting mode"
    out (uart_LCR),a                ; by writing 1 into bit 7 of the Line Control register
    nop								; These tiny "nop" pauses probably do nothing. TODO: Try removing them!

                                    ; Configure UART baud rate divisor for 7.3728 MHz xtal
                                    ; $01 = 460,800 (My favourite baud rate!)
									; $02 = 230,400
									; $04 = 115,200
									; $08 =  57,600
									; $0C =  38,400
									; $18 =  19,200
									; $20 =  14,400
									; $30 =   9,600

    ld a,b                          ; low byte of divisor
    out (uart_tx_rx),a
    nop
    ld a,0                          ; high byte
    out (uart_IER),a
    nop

    ld a,03H                        ; Configure stop bits etc, and exit
                                    ; "Divisor latch setting mode"

    out (uart_LCR),a                ; 8 bits, no parity, 1 stop bit, bit 7 = 0
	nop								; a slight pause to allow the UART to get going

	ld a, %10000001					; Turn on FIFO, with trigger level of 8.
	out (uart_ISR), a				; This definitely helps receive 16 chars very fast!

	ld a, c
	cp 0
	jr z, flowcontrol_done

	ld a, %00100010
	out (uart_MCR), a				; Enable auto flow control for /RTS and /CTS

flowcontrol_done:
	nop
	nop
    ret

; Print A to the screen as an ASCII character, preserving all registers.
print_a:
    push af                         ; Store A for a bit
print_a1:
    in a,(uart_LSR)                 ; check UART is ready to send.
    bit 5,a                         ; zero flag set to true if bit 5 is 0
    jp z, print_a1                  ; non-zero = ready for next char.

    pop af                          ; UART IS READY, GET OLD "A" BACK
    out (uart_tx_rx),a              ; AND SEND IT OUT
	ret


; To receive a char over Serial we need to check if there is one. If not we return 0.
; If there is, we get it and return it (in a).
char_in:
	in a,(uart_LSR)			; get status from Line Status Register
	bit 0,a					; zero flag set to true if bit 0 is 0 (bit 0 = Receive Data Ready)
							; "logic 0 = no data in receive holding register."
	jr z,char_in1    		; zero = no char received
	in a,(uart_tx_rx)		; Get the incoming char
	ret						; Return it in A
char_in1:
	ld a,0					; Return a zero in A
	ret

char_available:
	in a,(uart_LSR)			; get status from Line Status Register
	bit 0,a					; zero flag set to true if bit 0 is 0 (bit 0 = Receive Data Ready)
							; "logic 0 = no data in receive holding register."
	jr z,char_available1	; zero = no char received
	ld a, $FF		        ; return true
	ret						; in A
char_available1:
	ld a,0					; Return a zero in A
	ret


long_pause:
	ld bc,65000
    jr pause0
medium_pause:
	ld bc,45000
    jr pause0
short_pause:
	ld bc,100
pause0:
	dec bc
	ld a,b
	or c
	jp nz,pause0
	ret

disk_toggle:
	in a, (uart_MCR)
	and %00000100
	jr z, disk_on
	; fall through to...
disk_off:
 	; disk light off
	in a, (uart_MCR)
	and %11111011
	out (uart_MCR), a
	ret

disk_on:
	; disk light on
	in a, (uart_MCR)
	or %00000100
	out (uart_MCR), a
	ret

user_on:
	; user light on
	in a, (uart_MCR)
	or %00000001
	out (uart_MCR), a
	ret
	
user_toggle:
	; user1 light invert
	in a, (uart_MCR)
	and %00000001
	jr z, user_on
	; fall through to...
user_off:
 	; user light off
	in a, (uart_MCR)
	and %11111110
	out (uart_MCR), a
	ret

rom_toggle:
	in a, (uart_MCR)
	and %00001000
	jr z, rom_off
	; fall through to...
rom_on:
	; rom light on
	in a, (uart_MCR)
	and %11110111
	out (uart_MCR), a
;	ld 	a,01h                  ; pour le 74ls74 qui fait la commutation
;	out(ROM_DIS_CK),a			; supprimé : cmd directe par OUT2 du 16c550
;	ld	(rom_switch),a
	ret
	
rom_off:
	; rom light off
	in a, (uart_MCR)
	or %00001000
	out (uart_MCR), a
;	ld 	a,00h
;	out(ROM_DIS_CK),a
;	ld	(rom_switch),a
	ret

