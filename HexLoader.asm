      ;==============================================================================
      ; iLoad - Intel-Hex Loader - S260117
      ; Z80-MBC - HW ref: A041116 
      ;
      ; This program is embedded into IOS - I/O Subsystem - S221116 R230117
      ;
      ; Note: I've used a large part of the source from this site: 
      ;       http://www.vaxman.de/projects/tiny_z80/
      ;==============================================================================
      ;
      ;  Memory layout:
      ;
      ;  +-------+
      ;  ! $0000 !    not used (area available for loading)
      ;  !  ---  !
      ;  ! $FCEF !
      ;  +-------+
      ;  ! $FCF0 !    iLoad
      ;  !  ---  !
      ;  ! $FF73 !
      ;  +-------+
      ;  ! $FF74 !    not used
      ;  !  ---  !	(reserved for iLoad updates)
      ;  ! $FF7F !
      ;  +-------+
      ;  ! $FF80 !    reserved for uLoader S091216 R230117
      ;  !  ---  !
      ;  ! $FFB7 !
      ;  +-------+
      ;  ! $FFB8 !    reserved - not used
      ;  !  ---  !
      ;  ! $FFFF !
      ;  +-------+
      ;
      ;
      ;==================================================================================

      ;******************************************************************************
      ;***
      ;*** Main program
      ;***
      ;******************************************************************************

	  ;	org  	0B00h
      ;
      ; Constants definitions
      ;
      loader_ram equ	 $FFF0			; first RAM location used
      eos        equ	 $00            	; End of string
      cr         equ     $0D            	; Carriage return
      lf         equ     $0A            	; Line feed
      blanc      equ     $20            	; Space
      uart_tx	 equ	8				; Uart Tx port
      uart_rx	 equ	8				; Uart Rx port
      ;
      ; Program starting address
      ;
      HexLoader_start:
      ; Print a welcome message
      ;
      ld      hl, hello_msg
      call    puts
      call	  crlf
      ;
      ; Load an INTEL-Hex file into memory
      ;
      call  ih_load			; Load Intel-Hex file
	  
      ld	a, $ff			; Test for errors
      cp	h
      jr	nz, print_addr	; Jump if B<>$FF (no errors)
      cp	l
      jr	nz, print_addr	; Jump if C<>$FF (no errors)
      ;
      ; Print an error message and halt cpu
      ;				
      ld	hl, ih_load_msg_4
      call  puts
      ld	hl, load_msg_2
      call  puts
      halt
      ;
      ; Print starting address
      ;
      print_addr:
      push	hl				; Save starting addresss
      ld	hl, ih_load_msg_4
      call  puts
      ld	hl, load_msg_1
      call  puts
      pop	hl				; Load starting addresss
      call	print_word
      call	crlf
      call	crlf
      ;
      ; Flush remaining input data (if any) and jump to the loaded program
      ;				
      flush_rx:
      in    a, (uart_rx)	; Read a char from uart
      cp	$00			; Is <> $00?
      jr	nz, flush_rx	; Yes, read an other one
	  
	  ld a,(store_IX)
	  cp  00
	  jr z , _nogoto
	  ;else
      jp	(hl)			; No, so jump to starting addr
      ;
_nogoto:
      ld	hl, ih_load_msg_6
      call  puts
      call	crlf
      call	crlf
      jp $0000
	  
	  
	  ; Message definitions
      ;
      hello_msg       db   "Intel-Hex Loader - V1.1 (C)RLef 24 juin 2021 ==ROM==", eos
      load_msg_1      db   "Starting Address: ", eos
      load_msg_2      db   "Load error - System halted", eos
      ih_load_msg_1   db   "Attente de input stream...", eos
      ih_load_msg_2   db   "Syntax error!", eos
      ih_load_msg_3   db   "Checksum error!", eos 
      ih_load_msg_4   db   "iLoad: ", eos
      ih_load_msg_5   db   "Address violation!", eos
      ih_load_msg_6   db   "Pas de GOTO !", eos


      ;******************************************************************************
      ;***
      ;*** Subroutines
      ;***
      ;******************************************************************************


      ;
      ; Load an INTEL-Hex file (a ROM image) into memory. This routine has been 
      ; more or less stolen from a boot program written by Andrew Lynch and adapted
      ; to this simple Z80 based machine.
      ;
      ; The first address in the INTEL-Hex file is considerd as the Program Starting Address
      ; and is stored into HL.
      ;
      ; If an error is found HL=$FFFF on return.
      ;
      ; The INTEL-Hex format looks a bit awkward - a single line contains these 
      ; parts:
      ; ':', Record length (2 hex characters), load address field (4 hex characters),
      ; record type field (2 characters), data field (2 * n hex characters),
      ; checksum field. Valid record types are 0 (data) and 1 (end of file).
      ;
      ; Please note that this routine will not echo what it read from stdin but
      ; what it "understood". :-)
      ; 
      ih_load:
      push    af
      push    de
      push 	  bc
      ld	  bc, $ffff		; Init BC = $FFFF
      ld      hl, ih_load_msg_1
      call    puts
      call    crlf
      
 ; analyse d'une ligne du fichier hexa
 ih_load_loop:
      call    getc            ; Get a single character
      cp      cr              ; Don't care about CR
      jr      z, ih_load_loop
      cp      lf              ; ...or LF
      jr      z, ih_load_loop
      cp      blanc           ; ...or a space
      jr      z, ih_load_loop
      call    to_upper        ; Convert to upper case
      call    putc            ; Echo character
      cp      ':'             ; Is it a colon?                
      jp      nz, ih_load_err	; No - print an error message
      
;  nombre d'octets dans la ligne  ==> D
      call    get_byte        ; Get record length into A
      ld      d, a            ; Length is now in D
      ld      e, $0           ; Clear checksum
      call    ih_load_chk     ; Compute checksum
      
; lecture adresse 
      call    get_word        ; Get load address into HL
      ld	  a, $ff		; Save first address as the starting addr
      cp	  b
      jr	  nz, update_chk	; Jump if B<>$FF
      cp	  c
      jr	  nz, update_chk	; Jump if C<>$FF
      ld	  b, h		; Save starting address in BC
      ld	  c, l
      
      update_chk:
      ld      a, h            ; Update checksum by this address
      call    ih_load_chk
      ld      a, l
      call    ih_load_chk

; lecture record type 
      call    get_byte        ; Get the record type
      call    ih_load_chk     ; Update checksum
      cp      $1              ; Have we reached the EOF marker?
      jr      nz, ih_load_data; No - get some data

; end of file  record == 1
      call    get_byte        ; Yes - EOF, read checksum data
      call    ih_load_chk     ; Update our own checksum
      ld      a, e
      and     a               ; Is our checksum zero (as expected)?
      jr      z, ih_load_exit ; Yes - exit this routine
      
      ih_load_chk_err: 
      call	  crlf            ; No - print an error message
      ld      hl, ih_load_msg_4
      call    puts
      ld      hl, ih_load_msg_3
      call    puts
      ld	  bc, $ffff
      jr      ih_load_exit    ; ...and exit

; lecture des nb==D octets 
      ih_load_data:
      ld    a, d            ; Record length is now in A
      and   a               ; Did we process all bytes?
      jr    z, ih_load_eol  ; Yes - process end of line

;lecture un octets de data
      call  get_byte        ; Read two hex digits into A
      call  ih_load_chk     ; Update checksum
      jp    strap_1         ; on saute la verif de l'adresse de stockage
      push	hl			; Check if HL < iLoad used space
      push	bc
      and	a			; Reset flag C
      ld	bc, loader_ram	; BC = iLoad starting area
      sbc	hl, bc		; HL = HL - iLoad starting area
      pop	bc
      pop	hl
      jp	c,	store_byte	; Jump if HL < iLoad starting area protection du code du loader
      call  crlf			; Print an error message
      ld    hl, ih_load_msg_4
      call  puts
      ld    hl, ih_load_msg_5
      call  puts
      ld	bc, $ffff		; Set error flag
      jr	ih_load_exit	; ...and exit
      
strap_1:
store_byte:
      ld    (hl), a         ; Store byte into memory
      inc   hl              ; Increment pointer
      dec   d               ; Decrement remaining record length
      jr    ih_load_data    ; Get next byte
;      boucle sur le prochain byte dans la ligne 

ih_load_eol:
      call  get_byte        ; Read the last byte in the line
      call  ih_load_chk     ; Update checksum
      ld    a, e
      and   a               ; Is the checksum zero (as expected)?
      jr    nz, ih_load_chk_err
      call  crlf
      jp    ih_load_loop    ; Yes - read next line
      
      ih_load_err:
      call crlf
      ld    hl, ih_load_msg_4
      call  puts            ; Print error message
      ld    hl, ih_load_msg_2
      call  puts
      ld bc, $ffff
      
      ih_load_exit:
      call  crlf
      ld	h, b			; HL = BC
      ld	l, c
      pop	bc              ; Restore registers
      pop   de
      pop   af
      ret
      ;
      ; Compute E = E - A
      ;
      ih_load_chk:
      push	  bc
      ld      c, a            ; All in all compute E = E - A
      ld      a, e
      sub     c
      ld      e, a
      ld      a, c
      pop	  bc
      ret

      ;------------------------------------------------------------------------------
      ;---
      ;--- String subroutines
      ;---
      ;------------------------------------------------------------------------------

      ;
      ; Send a string to the serial line, HL contains the pointer to the string:
      ;
      puts:
      push    af
      push    hl
      
      call    FX_show_str_at_hl
      pop     hl
      pop     af
      ret
      ;
      ; Get a word (16 bit) in hexadecimal notation. The result is returned in HL.
      ; Since the routines get_byte and therefore get_nibble are called, only valid
      ; characters (0-9a-f) are accepted.
      ;
      get_word:
      push    af
      call    get_byte        ; Get the upper byte
      ld      h, a
      call    get_byte        ; Get the lower byte
      ld      l, a
      pop     af
      ret
      ;
      ; Get a byte in hexadecimal notation. The result is returned in A. Since
      ; the routine get_nibble is used only valid characters are accepted - the 
      ; input routine only accepts characters 0-9a-f.
      ;
      get_byte:
      push    bc              ; Save contents of B (and C)
      call    get_nibble      ; Get upper nibble
      rlc     a
      rlc     a
      rlc     a
      rlc     a
      ld      b, a            ; Save upper four bits
      call    get_nibble      ; Get lower nibble
      or      b               ; Combine both nibbles
      pop     bc              ; Restore B (and C)
      ret
      ;
      ; Get a hexadecimal digit from the serial line. This routine blocks until
      ; a valid character (0-9a-f) has been entered. A valid digit will be echoed
      ; to the serial line interface. The lower 4 bits of A contain the value of 
      ; that particular digit.
      ;
      get_nibble:
      call    getc            ; Read a character
      call    to_upper        ; Convert to upper case
      call    is_hex          ; Was it a hex digit?
      jr      nc, get_nibble  ; No, get another character
      call    nibble2val      ; Convert nibble to value
      call    print_nibble
      ret
      ;
      ; is_hex checks a character stored in A for being a valid hexadecimal digit.
      ; A valid hexadecimal digit is denoted by a set C flag.
      ;
      is_hex:
      cp      47h         ; Greater than 'F'?
      ret     nc              ; Yes
      cp      30h             ; Less than '0'?
      jr      nc, is_hex_1    ; No, continue
      ccf                     ; Complement carry (i.e. clear it)
      ret
      
      is_hex_1:
      cp      3ah         ; Less or equal '9*?
      ret     c               ; Yes
      cp      41h             ; Less than 'A'?
      jr      nc, is_hex_2    ; No, continue
      ccf                     ; Yes - clear carry and return
      ret
      
      is_hex_2
      scf                     ; Set carry
      ret
      ;
      ; Convert a single character contained in A to upper case:
      ;
      to_upper:
      cp      061H            ; sup a  Nothing to do if not lower case
      ret     c
      cp      07BH            ; > 'z'?'z' + 1
      ret     nc              ; Nothing to do, either
      and     05FH            ; Convert to upper case := reset bit 5 
      ret
     ;
      ; Expects a hexadecimal digit (upper case!) in A and returns the
      ; corresponding value in A.
      ;
      nibble2val:
      cp      3ah        ; Is it a digit (less or equal '9')?
      jr      c, nibble2val_1 ; Yes
      sub     7               ; Adjust for A-F
      
      nibble2val_1:
      sub     30h             ; Fold back to 0..15
      and     $f              ; Only return lower 4 bits
      ret
      ;
      ; Print_nibble prints a single hex nibble which is contained in the lower 
      ; four bits of A:
      ;
      print_nibble:
      push    af              ; We won't destroy the contents of A
      and     $f              ; Just in case...
      add     a, '0'             ; If we have a digit we are done here.
      cp      3ah        ; Is the result > 9?
      jr      c, print_nibble_1
      add     a, 7  ; Take care of A-F
      print_nibble_1:
      call    putc            ; Print the nibble and
      pop     af              ; restore the original value of A
      ret
      ;
      ; Send a CR/LF pair:
      ;
      crlf:
      push    af
      ld      a, cr
      call    putc
      ld      a, lf
      call    putc
      pop     af
      ret
      ;
      ; Print_word prints the four hex digits of a word to the serial line. The 
      ; word is expected to be in HL.
      ;
      print_word:
      push    hl
      push    af
      ld      a, h
      call    print_byte
      ld      a, l
      call    print_byte
      pop     af
      pop     hl
      ret
      ;
      ; Print_byte prints a single byte in hexadecimal notation to the serial line.
      ; The byte to be printed is expected to be in A.
      ;
      print_byte:
      push    af              ; Save the contents of the registers
      push    bc
      ld      b, a
      rrca
      rrca
      rrca
      rrca
      call    print_nibble    ; Print high nibble
      ld      a, b
      call    print_nibble    ; Print low nibble
      pop     bc              ; Restore original register contents
      pop     af
      ret

      ;------------------------------------------------------------------------------
      ;---
      ;--- I/O suroutines
      ;---
      ;------------------------------------------------------------------------------

      ;
      ; Send a single character to the serial line (a contains the character):
      ;
      putc :
	  call FX_print_a
      ;out     (uart_tx), a
      ret
      ;
      ; Wait for a single incoming character on the serial line
      ; and read it, result is in A:
      ;
      getc:
	  call FX_char_in
	  cp  0
	  jr z, getc
      ;in      a, (uart_rx)	; read a char from uart
      ;cp	  $ff				; is = $FF?
      ;jp	  z, getc			; if yes jump until a valid char is received
      ret

      .end