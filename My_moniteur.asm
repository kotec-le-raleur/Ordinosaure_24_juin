;**************************************************************
;*  programme de test pour le cablage de ma carte
;
;   led bleue   == rom light : éteinte ==> pin = 1 rom deactivee
;                            : allumé  ==> pin = 0 rom en fonction
;
;   led jaune   == USER light : éteinte ==> pin = 1  
;                             : allumé  ==> pin = 0  
;
;   led blanche == DISK light : éteinte ==> pin = 1 
;                             : allumé  ==> pin = 0 
; EDIT 24 juin
;   led bleue reliée  OUT2 du l'uart   éteinte ==>  ROM DESCATIVEE  == 64K de RAM
;                                      allumée ==>  ROM = $0000-$7FFF
;;
;
;**************************************************************
;   renommé en:
;   My_moniteur.asm    24 juin 2021
;**************************************************************
.Z80

Decode_0:	equ  $0    ;   0000 0000--0000 0111  	$00-$07 CH376S
Decode_1:	equ  $8    ;   0000 1000--0000 1111		$08-$0F 16C550
Decode_2:	equ  $10   ;   0001 0000--0001 0111		$10-$17
Decode_3:	equ  $18   ;   0001 1000--0001 1111		$18-$1F
Decode_4:	equ  $20   ;   0010 0000--0010 0111		$20-$27
Decode_5:	equ  $28   ;   0010 1000--0010 1111		$28-$2F
Decode_6:	equ  $30   ;   0011 0000--0011 0111		$30-$37
Decode_7:	equ  $38   ;   0011 1000--0011 1111		$38-$3F


;ROM_DIS_CK:	equ  $38    ;== Decode_7  défini dans uart.asm pour le switch ROM
LS374_CK:	equ  $30    ;== Decode_6



TOP_RAM			equ	0FFFFH
TOP_RAM_USER	equ 0FFD0H
store_hl		equ TOP_RAM_USER +  0					; Temporary store for hl
store_de 		equ TOP_RAM_USER +  2					; Temporary store for de
store_sp		equ TOP_RAM_USER +  4
current_page 	equ TOP_RAM_USER +  6					; Currently displayed monitor page
test_buffer 	equ TOP_RAM_USER +  8					; 32 x 24 char buffer (768 bytes)
rom_switch		equ TOP_RAM_USER +  10
store_ff		equ TOP_RAM_USER +  12
store_IX		equ TOP_RAM_USER +  14
store_IY		equ TOP_RAM_USER +  16

ADD_RAM:		EQU 0BEEFH
EXE_RAM     	EQU 0A000H
STACK_TOP   	EQU 0FF00H

;========================
;== debut du programme ==
;========================
	org	$0000	; eeprom page 0
      
Start_prog:
	DI
	IM	1
	ld    SP, STACK_TOP
	
    ld b, 16                    ; 57600  baud avec quartz = 14.745 baud
    ld c, $00                   ; No flow control
    call FX_configure_uart         ; Put these settings into the UART
	ld de,1000
	call Delay_ROM
	call FX_message
	db 13,10,"--ROM--test moniteur v.0:0014 ",13,10,13,10,0
	ld	a,0
	ld 	(current_page),a

	
LOOP_3:
	ld a,'>'
	call FX_print_a
	call FX_newline
M_1:	
	call FX_char_in			; get a char from keyboard
	cp 0					; If it's null, ignore it
	jr z,M_1
	call Mini_start
	
	ld de,400
	call Delay_ROM
	jp LOOP_3

;=========================
;test de mini moniteur
;=========================	

Mini_start:
	call FX_message
	db 'Input A= ',0

	push af
	call  FX_show_a_as_hex
 	call  FX_newline
	pop	 af

	cp '/'					; help
	jr nz,_nothelp
	jp show_welcome_message
	
_nothelp:
	cp '0'					; test fonction 0
	jr nz,_not0
	call FX_user_on
	call FX_message
	db 'Fonction 0',13,10
	db 'Lecture fichier .HEX and go',13,10,0
	ld	a,01
	ld (store_IX),a

	call HexLoader_start
	call FX_message
	db 'Lecture ok',13,10,0
	call FX_user_off
	call FX_show_all
	ret
	
_not0:
	cp '1'					; User light toggle
	jr nz,_not1
	call FX_message
	db 'User LED toggled!',13,10,0
	call FX_user_toggle
	ret
	
_not1:
	cp '2'					; ROM light on
	jr nz,_not3
	call FX_message
	db 'ROM light is now ON',13,10,0
	call FX_rom_on
	ret
	
_not3:
	cp '3'					; ROM light off
	jr nz,_not4
	call FX_message
	db 'ROM light is now OFF',13,10,0
	call FX_rom_off
	ret
	
_not4:
	cp '4'					; Disk LED toggle
	jr nz,_not5
	call FX_message
	db 'DISK LED toggled!',13,10,0
	call FX_disk_toggle
	ret
	
_not5:
	cp '5'					; Disk LED toggle
	jr nz,_not6
	call FX_message
	db 'test du transfert de code en ram !',13,10,0
	call poke_T_code
	call T_code_target		; execute le code := passe en ram 64k  et eeprom déactivée
 	ret

_not6:
	cp '6'					; test fonction 0
	jr nz,_notd
	call FX_user_on
	call FX_message
	db 'Fonction 6',13,10
	db 'Lecture fichier .HEX',13,10,0
	ld	a,00			; pour passer un param 
	ld (store_IX),a
	
	call HexLoader_start
	call FX_message
	db 'Lecture ok',13,10,0
	call FX_user_off
	call FX_show_all
	ret


	
_notd:
	cp 'h'					; Higher page
	jr nz,_noth
	call FX_message
	db 'Page +',13,10,0
	ld a,(current_page)
	inc a
	ld (current_page),a
	call FX_show_page
	ret
	
_noth:
	cp 'l'					; Lower page
	jr nz,_notl
	call FX_message
	db 'Page -',13,10,0
	ld a,(current_page)
	dec a
	ld (current_page),a
	call FX_show_page
	ret


_notl:
	cp 't'					; test string
	jr nz,_notb             ; strap
	call FX_message
	db 'test goto 500',13,10,0
	
	ld	hl,TEXTE_2
	call FX_show_str_at_hl
	call montest
	ret

_notb:
	cp 'b'				 
	jr nz,_notw
	call FX_message
	db 'get byte ',13,10,0
	call FX_get_hex_byte		;Gets HEX byte into A
	ld (current_page),a
	call FX_newline
	call FX_show_all
	ret

_notw:
	cp 'w'					 
	jr nz,_notg
	call FX_message
	db 'get word',13,10,0
	call FX_get_hex_word    ;Gets two HEX bytes into HL
	call FX_newline
	call FX_show_all
	ret

_notg:
	cp 'g'					 
	jr nz,_notr
	call FX_message
	db 'go address',13,10,0
	call FX_get_hex_word    ;Gets two HEX bytes into HL
	call FX_show_all
	jp	(hl)
	ret
	
_notr:
	cp 'r'					 
	jr nz,_notx
	call FX_message
	db 'RAZ ram 8000-AFFF',13,10,0
	ld hl,8000h
_lp0:
	ld (hl),0
	inc hl
	ld a,h
	cp 0B0h
	jr nz,_lp0
	call FX_message
	db 'ram OK',13,10,0
	ret

_notx:
	call FX_message
	db 'commande non supportee',13,10,0
    ret



montest:
	call FX_message
	db 'tapez une touche',13,10,0
mt1:	
	call FX_char_in			; get a char from keyboard
	cp 0					; If it's null, ignore it
	jr z,mt1
	cp 01BH				; escape
	jr z,mt2 				; on sort
	push af
	pop  bc 
	call FX_show_all
	call mt_to_upper
	call FX_show_all
	ret
	
mt2:
	call FX_message
	db 'Escape !',13,10,0
	ret
	
	; Convert a single character contained in A to upper case:
mt_to_upper:
      cp      061H            ; sup a  Nothing to do if not lower case
      ret     c
      cp      07BH         ; > 'z'?'z' + 1
      ret     nc              ; Nothing to do, either
      and     05FH            ; Convert to upper case := reset bit 5 
      ret

	
Delay_ROM:

      dec   de
      ld    a,d
      or    e
      jr    nz, Delay_ROM
      ret

Delay_ROM_2:

      dec   d
      jr    nz, Delay_ROM_2
      ret

show_welcome_message:
	call FX_message
	db 13,10,13,10,13,10
	db '   version 24/06/21 en ==ROM==',13,10
	db '/ = Show this Menu',13,10
	db '0 = Hex-load and go', 13, 10
	db '1 = User LED toggle', 13, 10
	db '2 = ROM ON', 13, 10
	db '3 = ROM OFF', 13, 10
	db '4 = Disk LED toggle', 13, 10
	db '5 = Transfert', 13, 10
	db '6 = HexLoad and return', 13, 10
	db 'h = Dump Page +', 13, 10
	db 'l = Dump Page -', 13, 10
	db 't = Test fonction', 13, 10
	db 'w = Get Word', 13, 10
	db 'b = Get Byte', 13, 10
	db 'g = Goto HL', 13, 10
	db 'r = RAZ ram $0000-$B000', 13, 10
	db 13,10,0
	ret


TEXTE_1:
	db "texte imprime par show_string_at_hl",10,13,0
TEXTE_2:
	db "test TEXTE_2",10,13,0
;ce code est la séquence de transfert  du moniteur en RAM 
; Copie de ROM $000--> RAM $8000,  puis déactivation de la rom, puis recopie RAM en $8000 en $000
T_code_debut:
		db  $21, $00, $00, $11, $00, $80, $01, $00
		db  $4C, $ED, $B0, $DB, $0C, $F6, $08, $D3
		db  $0C, $CD, $A0, $CF, $21, $00, $80, $11
		db  $00, $00, $01, $00, $4C, $ED, $B0, $C9
		db  $11, $E8, $03, $1B, $7A, $B3, $20, $FB, $C9
T_code_fin:
		nop
T_code_target: equ $CF80		
poke_T_code:
	ld hl,T_code_debut
	ld de,T_code_target
	ld bc,T_code_fin-T_code_debut
	ldir
	ret
	

;*************************************************************
;  code importé du projet  Hexloader
;*************************************************************
include "Hexloader.asm"
;
;  Fix1000 inclu tous les autres morceaux 
; il reste un peu de place entre la fin et $800
	ORG  $0800
FX_configure_uart: 	jp configure_uart
				nop
FX_char_in:		 	jp char_in
				nop
FX_clear_screen:	jp clear_screen
				nop
FX_disk_off:	 	jp disk_off
				nop
FX_disk_on:	 	 	jp disk_on
				nop
FX_disk_toggle:	 	jp disk_toggle
				nop
FX_user_off:	 	jp user_off
				nop
FX_user_on:	 	 	jp user_on
				nop
FX_user_toggle:	 	jp user_toggle
				nop
FX_rom_off:	 	 	jp rom_off
				nop
FX_rom_on:	 	 	jp rom_on
				nop
FX_rom_toggle:	 	jp rom_toggle
				nop
FX_message:	 	 	jp message
				nop
FX_newline:	 	 	jp newline
				nop
FX_print_a:	 	 	jp print_a
				nop
FX_show_a_as_char:	jp show_a_as_char
				nop
FX_show_a_as_hex:	      jp show_a_as_hex
				nop
FX_show_all:	 	jp show_all
				nop
FX_show_de_as_hex:	jp show_de_as_hex
				nop
FX_show_hl_as_hex:	jp show_hl_as_hex
				nop
FX_show_page:	 	jp show_page
				nop
FX_show_str_at_hl:	jp show_str_at_hl
				nop
FX_get_hex_byte:	      jp GET_HEX_BYTE
				nop
FX_get_hex_word:	      jp GET_HEX_WORD;
				nop
	 
include "uart.asm"
include "message.asm"	
include "printing.asm"
include "conio.asm"	

      end

