; This is the main routine. Breakpoints set here activate the debugger

ProgStart:


;library offsets
exec           equ $4
openlibrary    equ -$198
closelibrary   equ -414
forbid         equ -132
permit         equ -138
supervisor     equ -30
loadview       equ -222
waittoff       equ -270
ownblitter     equ -456
disownblitter  equ -462
waitblit       equ -228


; My offsets
old_View_off   equ 34
old_Clist1_off equ 38
old_Clist2_off equ 50

start:
                       movem.l    d1-d7/a0-a6,-(sp)                                  ; Preserve registers

; Set my copperlist up
                       jsr        Setup
                       bsr        InitMouse
                       bsr        setnewcop
                       jsr        takesys

; Now setup my system
                       move.w     #$87e0,DMACON(a5)
                       move.w     #$C010,INTENA(a5)                                  ; Vertical blank, and master enable	

                       move.l     copperlist,COP1LCH(a5)                             ; pop my copperlist in
                       move.w     #0,COPJMP1(a5)                                     ; Initiate copper

MAINLOOP:

.wframe
                       btst       #0,$dff005
                       bne.b      .wframe
                       cmp.b      #$2a,$dff006
                       bne.b      .wframe
.wframe2
                       cmp.b      #$2a,$dff006
                       beq.b      .wframe2

                       ;bsr        ReadInput
                       bsr        MouseEventHandler
                       bsr        updateSpriteCoordinates
                       bsr        updateSpriteWords
                        
                       btst       #6,$BFE001
                       bne        .noblit
                       bsr        GetPosition
                       bsr        BLIT_PIPE_I

.noblit                

.tst_fire1
;                       btst       #8,d7                                              ; Fire 1
;                       beq        .tst_fire2
;                       bra        BLIT_PIPE_I

.tst_fire2
;                       btst       #9,d7                                              ; Fire 2
                       beq        .done

.done
                       move.b     #0,spr_cur_frame
                       bsr        AnimateSprite

; --vv added by mcgeezer - Updates the debug window every frame if ENABLE_DEBUG = 1	 
                       IFNE       ENABLE_DEBUG
                       bsr        agdDebugWindow
                       ENDC
; --^^ added by mcgeezer	

                        bra        MAINLOOP

GetPosition:
; Gets the x/y position of the character, and returns the correct offset to blit.
; Input

;                       lea        paneltable,a0
                       moveq      #0,d0
                       moveq      #0,d1
                       move.w     mouse_x,d0
                       move.w     mouse_y,d1
                       sub.b      #65,d0                                             ; 63
                       sub.b      #44,d1                                             ; 44
                       rts

paneltable:            dc.w       71,103,135,197,199,231
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


restoresys:
	; Restore the system
                       move.w     #$7fff,DMACON(a5)
                       move.w     dmasys,DMACON(a5)

                       move.w     #$7fff,INTENA(a5)
                       move.w     intsys,INTENA(a5)
	
                       move.w     #$7fff,INTREQ(a5)
                       move.w     intrqs,INTREQ(a5)
	
                       move.l     sys1cop,COP1LCH(a5)
;	move.l		sys2cop,COP2LCH(a5)


                       ; Restore the gfx view
                       move.l     gfxbase,a0
                       move.l     sysview,a1
	
                       jsr        loadview(a6)                                       ; Restore the original view
	
                       move.l     a0,d0                                              ; GFXBase ready for closing
                       MOVE.l     $4,A6                                              ; Execbase
                       jsr        permit(a6)                                         ; Enable multitasking
	
exit:
                       jsr        closelibrary(a6)                                   ; Close gfx library
	
                       movem.l    (sp)+,d1-d7/a0-a6                                  ; Restore registers
                       move.l     #0,d0                                              ; Ensure d0 is cleared
                       rts                                                           ; exit

; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

speedSpriteX:          equ        1
speedSpriteY:          equ        1

screenLeftBoundary:    equ        70                                                 ;$46
screenRightBoundary:   equ        202                                                ;$ca
screenTopBoundary:     equ        83                                                 ;$54
screenBottomBoundary:  equ        248

;	Up		-	   1
;	Down		-	   2
;	Left		-	   4
;	Right		-	   8

; d7=bit field of movement
updateSpriteCoordinates:
                       move.w     mouse_x,d2
                       move.w     mouse_y,d0
                       move.w     #sprheight,d1
                       bra        .left
                       clr.l      d4
                       move.b     d7,d4

.none:                 bra        .exit

.left:                 cmp.w      #screenLeftBoundary,d2
                       bgt.s      .right

                       move.w     #screenLeftBoundary,d2
                       move.w     d2,mouse_x

		
.right:                cmp.w      #screenRightBoundary,d2
                       blt.s      .up

                       move.w     #screenRightBoundary,d2
                       move.w     d2,mouse_x
                      

		
.up:                   cmp.w      #screenTopBoundary,d0
                       bgt.s      .down

                       move.w     #screenTopBoundary,d0
                       move.w     d0,mouse_y


.down:                 cmp.w      #screenBottomBoundary,d0
                       blt.s      .exit
                       
                       move.w     #screenBottomBoundary,d0
                       move.w     d0,mouse_y
                       bra.s      .update

                       nop

.update                move.w     d2,spr_xPos 
                       move.w     d2,mouse_x
                       move.w     d0,spr_yPos
                       move.w     d0,mouse_y 
.exit:                 rts

                           ;0    4   8     12    16    20       24         28
;.moves:                dc.l       .none,.up,.down,.none,.left,.up_left,.down_left,.none
;                       dc.l       .right,.up_right,.down_right,.none,.none,.none,.none,.none
                           ;32    36         40         44    48    52     56    60


; Test MOVEMENT
; Registers used by this routine

; d0 - Sprite Y position
; d1 - Sprite height
; d2 - Sprite X position
updateSpriteWords:
                       move.l     d3,-(a7)                                           ; Save d3 cos we trash it
                       moveq      #0,d3
		
                       btst       #8,d0                                              ; Y Position above 255?
                       beq.s      .vstart                                            ; No....
                       or.w       #4,d3                                              ; Yes, set vstart highbit

.vstart:               add.w      d0,d1                                              ; calc sprite height position
                       btst       #8,d1                                              ; Bottom above 255?
                       beq.s      .vstop                                             ; No....
                       or.w       #2,d3                                              ; Yes.. so set vstop highbit

.vstop:              						

		; Update control words
                       move.b     d0,spr_data                                        ; y position into control word
                       move.b     d1,spr_data+2                                      ; Finish of sprite into control word
                       move.b     d2,spr_data+1
                       move.b     d3,spr_data+3                                      ; Set high bits if needed
                       move.l     (a7)+,d3                                           ; Restore d3
                       rts


; Blitter Routines



;***********************************************************************************************
	
                       SECTION    coplistexample,DATA_C

copperlist:            dc.l       0	
                       even
gfxname:
                       dc.b       "graphics.library",0
                       even
gfxbase:
                       dc.l       0
                       even
sys1cop:               dc.l       0                                                  ; System copperlist
sys2cop:               dc.l       0                                                  ; System copperlist2
sysview:               dc.l       0                                                  ; Systemview

; Below we have sprite information, this includes variables for saving the various sprite
; memory locations within the copperlist. This will allow us to update the copperlist dynamically
; Allowing some animation.

; Sprite Data

spr0copaddr:           dc.l       0                                                  ; Address within copperlist to adjust sprite pointer
spr1copaddr:           dc.l       0
spr2copaddr:           dc.l       0                                                  ; Address within copperlist to adjust sprite pointer
spr3copaddr:           dc.l       0
myimage_addr:          dc.l       0

spr_xPos               dc.w       $40
spr_yPos               dc.w       $2C
spr_cur_frame:         dc.b       0
                       even
spr_data               dc.w       $2C40,$8200                                        ; Control words for sprite

                       even

SpritePal:    
                       dc.w       $0000,$0FFF,$0232,$0555,$0777,$0999,$0AAA,$0CCC
                       dc.w       $06B0,$0170,$05BC,$0367,$007B,$0048,$0E88,$0B55

                       include    "Data\Sprites\Pipe_Sprites_32x32y3bpp.src"

NullSpr:
                       dc.w       $2a20,$2b00
                       dc.w       0,0
                       dc.w       0,0

myimage:
                       cnop       0,8
                       incbin     "Data\GameScreen_320x256x5.iff"
                       even

pipetiles:             cnop       0,8
                       incbin     "Data\Gfx\Pipe_Sprites_32x32y5bpp.raw"

                       ; Interleaved pipe sprites
pipetiles_inter:       incbin     "Data\Gfx\PipeSprites_32x32y5bpp_IL.raw" 
                       even
pipemask:              cnop       0,8
                       incbin     "Data\Pipe_Sprites_32x32_Mask.raw"

REPTEX: 
                       dc.w       (($40&$FF)<<8)|(($40&$1FE)>>1)
               ; DC.W       (((spr_yPos+sprheight)&$FF)<<8)!((spr_yPos &$100)>>6)!(((spr_yPos+sprheight)&$100)>>7)!(spr_xPos&$1)
;structs:
;    STRUCTURE   Player1,0
;    UWORD       Plyr1_x                                                    ; Current X position                                                     
;    UWORD       Plyr1_y                                                    ; Current Y positiom
;    UWORD       Plyr1_CurrentBob_frame                                     ; Current pipe held by player

;    STRUCTURE   Player2,0
;    UWORD       Plyr2_x                                                    ; Current X position                                                     
;    UWORD       Plyr2_y                                                    ; Current Y positiom
;    UWORD       Plyr2_CurrentBob_frame                                     ; Current pipe held by player