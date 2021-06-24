;*************************************************************
;  code importé du projet
;*************************************************************

; TOP_RAM			equ	0FFFFH
; TOP_RAM_USER	equ 0FFD0H
; store_hl		equ	TOP_RAM_USER +  0					; Temporary store for hl
; store_de 		equ TOP_RAM_USER +  2					; Temporary store for de
; store_sp		equ	TOP_RAM_USER +  4
; current_page 	equ TOP_RAM_USER +  6					; Currently displayed monitor page
; test_buffer 	equ TOP_RAM_USER +  8					; 32 x 24 char buffer (768 bytes)
; rom_switch		equ TOP_RAM_USER +  10
; store_ff		equ	TOP_RAM_USER +  12
; store_IX		equ TOP_RAM_USER +  14
; store_IY		equ TOP_RAM_USER +  16

	 
FX_configure_uart: 	 jp configure_uart
					 nop
FX_char_in:		 	 jp char_in
					 nop
FX_clear_screen:	 jp clear_screen
					 nop
FX_disk_off:	 	 jp disk_off
					 nop
FX_disk_on:	 	 	 jp disk_on
					 nop
FX_disk_toggle:	 	 jp disk_toggle
					 nop
FX_user_off:	 	 jp user_off
					 nop
FX_user_on:	 	 	 jp user_on
					 nop
FX_user_toggle:	 	 jp user_toggle
					 nop
FX_rom_off:	 	 	 jp rom_off
					 nop
FX_rom_on:	 	 	 jp rom_on
					 nop
FX_rom_toggle:	 	 jp rom_toggle
					 nop
FX_message:	 	 	 jp message
					 nop
FX_newline:	 	 	 jp newline
					 nop
FX_print_a:	 	 	 jp print_a
					 nop

FX_show_a_as_char:	 jp show_a_as_char
					 nop
FX_show_a_as_hex:	 jp show_a_as_hex
					 nop
FX_show_all:	 	 jp show_all
					 nop
FX_show_de_as_hex:	 jp show_de_as_hex
					 nop
FX_show_hl_as_hex:	 jp show_hl_as_hex
					 nop
FX_show_page:	 	 jp show_page
					 nop
FX_show_str_at_hl:	 jp show_str_at_hl
					 nop
					 
FX_get_hex_byte:	 jp GET_HEX_BYTE
					 nop
FX_get_hex_word:	 jp GET_HEX_WORD;
					 nop
	 
	 
; uart routines
; These are routines connected with the 16C550 uart.
; Initialises the 16c550c UART for input/output
include "uart.asm"

	; Use this handy helper function to display an inline message easily.
	; It preserves all registers (which was tricky to do).
include "message.asm"	


include "printing.asm"
include "conio.asm"	

end
