;***************************************************************************
;  PROGRAM:			CONIO       
;  PURPOSE:			Subroutines for console I/O
;  ASSEMBLER:		TASM 3.2        
;  LICENCE:			The MIT Licence
;  AUTHOR :			MCook
;  CREATE DATE :	19 May 15
;***************************************************************************
newline:
	push af
	ld a,13
	call print_a
	ld a,10
	call print_a
	pop  af
	ret
	
space:
	push af
	ld a,32
	call print_a
	pop  af
	ret

;			
;***************************************************************************
;TO_UPPER   corrigé le 19 juin 2021 par moi !
;Function: Convert character in Accumulator to upper case 
;***************************************************************************
TO_UPPER:       
      cp      061H            ; sup a  Nothing to do if not lower case
      ret     c
      cp      07BH         ; > 'z'?'z' + 1
      ret     nc              ; Nothing to do, either
      and     05FH            ; Convert to upper case := reset bit 5 
      ret
			
			
;***************************************************************************
;CHAR_ISHEX
;Function: Checks if value in A is a hexadecimal digit, C flag set if true
;***************************************************************************		
CHAR_ISHEX:         
										;Checks if Acc between '0' and 'F'
			CP      047H         		;(Acc) > 'F'? 
            RET     NC              	;Yes - Return / No - Continue
            CP      030H             	;(Acc) < '0'?
            JR      NC,CHAR_ISHEX_1 	;Yes - Jump / No - Continue
            CCF                     	;Complement carry (clear it)
            RET
CHAR_ISHEX_1:       
										;Checks if Acc below '9' and above 'A'
			CP      03AH         		;(Acc) < '9' + 1?
			RET     C               	;Yes - Return / No - Continue (meaning Acc between '0' and '9')
            CP      041H             	;(Acc) > 'A'?
            JR      NC,CHAR_ISHEX_2 	;Yes - Jump / No - Continue
            CCF                     	;Complement carry (clear it)
            RET
CHAR_ISHEX_2:        
										;Only gets here if Acc between 'A' and 'F'
			SCF                     	;Set carry flag to indicate the char is a hex digit
            RET
			
;***************************************************************************
;GET_HEX_NIBBLE
;Function: Translates char to HEX nibble in bottom 4 bits of A
;***************************************************************************
GET_HEX_NIB:      
			CALL	char_in
			cp 	0
			jr 		z,  GET_HEX_NIB
;			call    print_a
			call 	TO_UPPER			;forçage en majuscule
            CALL    CHAR_ISHEX      	;Is it a hex digit?
            JR      NC,GET_HEX_NIB  	;Yes - Jump / No - Continue
			
			CALL    print_a				; echo
			CP      03AH         		;Is it a digit less or equal '9' + 1?
            JR      C,GET_HEX_NIB_1 	;Yes - Jump / No - Continue
            SUB     $07             	;Adjust for A-F digits
GET_HEX_NIB_1:                
			SUB     030H             	;Subtract to get nib between 0->15
            AND     $0F             	;Only return lower 4 bits
            RET	
				
;***************************************************************************
;GET_HEX_BTYE
;Function: Gets HEX byte into A
;***************************************************************************
GET_HEX_BYTE:
            CALL    GET_HEX_NIB			;Get high nibble
            RLC     A					;Rotate nibble into high nibble
            RLC     A
            RLC     A
            RLC     A
            LD      B,A					;Save upper four bits
            CALL    GET_HEX_NIB			;Get lower nibble
            OR      B					;Combine both nibbles
            RET				
			
;***************************************************************************
;GET_HEX_WORD
;Function: Gets two HEX bytes into HL
;***************************************************************************
GET_HEX_WORD:
			PUSH    AF
            CALL    GET_HEX_BYTE		;Get high byte
            LD		H,A
            CALL    GET_HEX_BYTE    	;Get low byte
            LD      L,A
            POP     AF
            RET
		
;***************************************************************************
;PRINT_HEX_NIB
;Function: Prints a low nibble in hex notation from Acc to the serial line.
;***************************************************************************
PRINT_HEX_NIB:
			PUSH 	AF
            AND     $0F             	;Only low nibble in byte
            ADD     A, 030H             	;Adjust for char offset
            CP      03AH         	;Is the hex digit > 9?
            JR      C,PRINT_HEX_NIB_1	;Yes - Jump / No - Continue
            ADD     A, 65 - 48 - 10	;Adjust for A-F  == 7
PRINT_HEX_NIB_1:
			CALL	print_a        	;Print the nibble
			POP		AF
			RET
				
;***************************************************************************
;PRINT_HEX_BYTE
;Function: Prints a byte in hex notation from Acc to the serial line.
;***************************************************************************		

; equivalent à printing->show_a_as_hex
PRINT_HEX_BYTE:
			PUSH	AF					;Save registers
            PUSH    BC
            LD		B,A					;Save for low nibble
            RRCA						;Rotate high nibble into low nibble
			RRCA
			RRCA
			RRCA
            CALL    PRINT_HEX_NIB		;Print high nibble
            LD		A,B					;Restore for low nibble
            CALL    PRINT_HEX_NIB		;Print low nibble
            POP     BC					;Restore registers
            POP		AF
			RET
			
;***************************************************************************
;PRINT_HEX_WORD
;Function: Prints the four hex digits of a word to the serial line from HL
;***************************************************************************
; equivalent à printing->show_hl_as_hex
PRINT_HEX_WORD:     
			PUSH 	HL
            PUSH	AF
            LD		A,H
			CALL	PRINT_HEX_BYTE		;Print high byte
            LD		A,L
            CALL    PRINT_HEX_BYTE		;Print low byte
            POP		AF
			POP		HL
            RET		


			