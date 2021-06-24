;**************************************************************
;*  programme de transfert ROM vers RAM
;**************************************************************
.Z80
;========================
;== debut du programme ==
;========================
	org		$CF80	  
      
Start_prog:
	
	ld	hl, $0000
	LD 	DE,	$8000
	ld	bc,	$4C00
	ldir
	
; switch rom == ram 	
rom_off:
	in a, (12)
	or %00001000
	out (12), a
	call _delay
	ld	hl, $8000
	LD 	DE,	$0000
	ld	bc,	$4C00
	ldir
	ret 
	
_delay:
	ld de,1000
_delayloop:
      dec   de
      ld    a,d
      or    e
      jr    nz, _delayloop
      ret
	

	END