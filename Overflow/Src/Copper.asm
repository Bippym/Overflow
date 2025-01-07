; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-

	; Now we work out the bitplane info.
	; Bitplane pointers need to go into the 4 registers. Each bitplane is 10240 bytes
	;
	; d7 - Number of bitplanes
	; a0 - Pointer to copperlist
	; d1 - Pointer to image - We add 10240 after each pointer has been copied into

setnewcop:

        movem.l    d0-d7/a0-a1,-(sp)
        move.l     copperlist,a0                               ; address of our copperlist
        move.l     #FMODE<<16+0,(a0)+                          ; Set FMODE into copperlist
        move.w     #BPLCON0,(a0)+
        move.w     #$5200,(a0)+                                ; Lowres 4bpp screen 010000100000000
        move.w     #BPLCON1,(a0)+
        move.w     #0,(a0)+
        move.w     #BPLCON2,(a0)+
        move.w     #$24,(a0)+
        move.w     #BPL1MOD,(a0)+
        move.w     #(SCREEN_WIDTH/8)*(SCREEN_DEPTH-1),(a0)+
        move.w     #BPL2MOD,(a0)+
        move.w     #(SCREEN_WIDTH/8)*(SCREEN_DEPTH-1),(a0)+
        move.l     #DIWSTRT<<16+$2c81,(a0)+
        move.l     #DIWSTOP<<16+$2cc1,(a0)+                    ; f4c1/2c
                      ;move.l     #DIWSTOP<<16+$38c1,(a0)+                                         ; PAL offset > 256
        move.l     #DDFSTRT<<16+$0038,(a0)+
        move.l     #DDFSTOP<<16+$00D0,(a0)+

        lea        myimage,a1                                  ; My image address
.loop   cmp.l      #"BODY",(a1)                                ; We need to search for the body of the image
        beq.s      .found                                      ; Have we found it? Branch if so
        addq       #2,a1                                       ; Not found, so lets increment and try again
        bra.s      .loop


.found  addq       #8,a1                                       ; Move past the BODY header

        moveq      #SCREEN_DEPTH-1,d7                          ; Number of bitplanes
        move.l     a1,myimage_addr
	
        move.l     #(BPL0PTH<<16),d0                           ; Bitplane high pointer to $00E00000
.1      move.l     a1,d1                                       ; Address of image copied
        swap       d1                                          ; swap the address round so the high word is moveable
        move.w     d1,d0                                       ; and move it into d0 (d0 = $00E0xxxx)
        move.l     d0,(a0)+                                    ; Pop it into the copperlist
        swap       d1                                          ; Swap the address back
        add.l      #$20000,d0                                  ; move to the BPLxPTL
        move.w     d1,d0                                       ; Low part of the address in
        move.l     d0,(a0)+                                    ; ANd pop the address into the copper
        add.l      #$20000,d0                                  ; Next BPLxPTH (next bitplane)
        add.l      #(SCREEN_WIDTH/8),a1                        ; Next bitplane image
        dbf        d7,.1                                       ; loop


; Finds the palette within the IFF and sets the palette registers

SetPalette:

        lea        myimage,a1                                  ; Image into a1 again to search for the palette	
.loop   cmp.l      #"CMAP",(a1)                                ; Looking for the colormap
        beq        .found                                      ; Have we found the colormap
        addq       #2,a1                                       ; Not found, move on :)
        bra.s      .loop
	
.found  addq       #8,a1                                       ; Jump over the header

        move.l     #SCREEN_DEPTH<<2-1,d7                       ; Number of colours in the image
	
        clr.l      d4
        clr.l      d3
        clr.l      d2
        clr.l      d1
	
        move.l     #(COLOR00<<16),d5                           ; First colour entry
.2      move.b     (a1)+,d1                                    ; Red 
        move.b     (a1)+,d2                                    ; Green
        move.b     (a1)+,d3                                    ; Blue
	
        and.b      #%11110000,d1                               ; Drop lower nibble
        and.b      #%11110000,d2
        and.b      #%11110000,d3	
        move.b     d1,d5                                       ; Move red
        lsl.w      #4,D5                                       ; Shift to the left
        or.w       D2,D5                                       ; Move green in
        lsl.w      #4,D5                                       ; ANd shift
        or.w       D3,D5                                       ; Move in blue
        lsr.w      #4,d5                                       ; fix the offset
	
        move.l     d5,(a0)+                                    ; Put the colour register into the copperlist
	
        add.l      #$20000,d5                                  ; Next colour register
        dbf        d7,.2                                       ; Loop

              ; Set Palette entries 16-31 for the sprites
        move.l     #16-1,d7                                    ; No' Colours
        lea        SpritePal,a1                                ; Address of sprite colours
        move.l     #(COLOR16<<16),d0                           ; Palette 16
.4      move.w     (a1)+,d0                                    ; colour copied
        move.l     d0,(a0)+                                    ; Pop it into the copperlist
        add.l      #$20000,d0                                  ; move to the SPR0PTL
        dbf        d7,.4


	; We work out the sprite info.
	; Sprite pointers need to go into the 16 registers. 
        ; d7 - Number of sprites (8-1)
	; a0 - Pointer to offset in the copperlist
        ; a1 - Point to the sprite data
	; d1 - Pointer to sprite data image
	
             ; Set sprite pointers into registers
SetSprite:
              ; left half of the sprite. Sprite 0
        move.l     a0,spr0copaddr                              ; Save the offset to the sprite copper address
        move.l     #8-4,d7                                     ; Number of sprites (8 - the attached sprites 0/1 and 2/3)

        lea        Sprite1a,a1                                 ; Sprite address
        move.l     #(SPR0PTH<<16),d0                           ; Sprite high pointer $01020000
        move.l     a1,d1                                       ; Address of sprite copied
        swap       d1                                          ; swap the address round so the high word is moveable
        move.w     d1,d0                                       ; and move it into d0 (d0 = $0102xxxx)
        move.l     d0,(a0)+                                    ; Pop it into the copperlist
        swap       d1                                          ; Swap the address back
        add.l      #$20000,d0                                  ; move to the SPR0PTL
        move.w     d1,d0                                       ; Low part of the address in
        move.l     d0,(a0)+                                    ; And pop the address into the copper

              ; Sprite 1, attached. Sprite 1 
        move.l     a0,spr1copaddr                              ; Save attached sprite address
        lea        Sprite1b,a1                                 ; Attach sprite location
        move.l     #(SPR1PTH<<16),d0                           ; Sprite 1 high pointer
        move.l     a1,d1                                       ; Address of sprite copied
        swap       d1                                          ; swap the address round so the high word is moveable
        move.w     d1,d0                                       ; and move it into d0 (d0 = $0102xxxx)
        move.l     d0,(a0)+                                    ; Pop it into the copperlist
        swap       d1                                          ; Swap the address back
        add.l      #$20000,d0                                  ; move to the SPRxPTL
        move.w     d1,d0                                       ; Low part of the address in
        move.l     d0,(a0)+                                    ; And pop the address into the copper

              ; Right half of the sprite. Sprite 2
        move.l     a0,spr2copaddr                              ; Save attached sprite address
        lea        Sprite2a,a1                                 ; Attach sprite location
        move.l     #(SPR2PTH<<16),d0                           ; Sprite 1 high pointer
        move.l     a1,d1                                       ; Address of sprite copied
        swap       d1                                          ; swap the address round so the high word is moveable
        move.w     d1,d0                                       ; and move it into d0 (d0 = $0102xxxx)
        move.l     d0,(a0)+                                    ; Pop it into the copperlist
        swap       d1                                          ; Swap the address back
        add.l      #$20000,d0                                  ; move to the SPRxPTL
        move.w     d1,d0                                       ; Low part of the address in
        move.l     d0,(a0)+                                    ; And pop the address into the copper

              ; Sprite 2, attached. Sprite 3
        move.l     a0,spr3copaddr                              ; Save attached sprite address
        lea        Sprite2b,a1                                 ; Attach sprite location
        move.l     #(SPR3PTH<<16),d0                           ; Sprite 1 high pointer
.3      move.l     a1,d1                                       ; Address of sprite copied
        swap       d1                                          ; swap the address round so the high word is moveable
        move.w     d1,d0                                       ; and move it into d0 (d0 = $0102xxxx)
        move.l     d0,(a0)+                                    ; Pop it into the copperlist
        swap       d1                                          ; Swap the address back
        add.l      #$20000,d0                                  ; move to the SPRxPTL
        move.w     d1,d0                                       ; Low part of the address in
        move.l     d0,(a0)+                                    ; And pop the address into the copper

        move.b     #1,spr_cur_frame                            ; Set the initial animation frame


              ; Set the null sprites for the remaining 6 sprites
        add.l      #$20000,d0                                  ; next SPRxPTH
        lea        NullSpr,a1                                  ; pointer to the null sprite data
        dbf        d7,.3
                                               ; loop
; --vv added by mcgeezer - Creates a debug window at line 240 if ENABLE_DEBUG is 1
        IFNE	ENABLE_DEBUG
	        bsr		agdCreateDebugCopper
        endc
; --^^ added by mcgeezer
 
        move.l     #$FFFFFFFE,(a0)                             ; End the copperlist
        movem.l    (sp)+,d0-d7/a0-a1

        rts