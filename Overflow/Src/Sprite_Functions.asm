; This file contains some sprite and blitting routines I am developing. I set a breakpoint and the debugger
; does not activate


; All sprite functions

MoveSprite:

; Moves the sprite/cursor without animating it
; Registers used
; d0 - Current sprite frame
; 

                       clr.l      d0
              ; Set sprite control words. Attached sprites share the same control except for the attach bit

                       lea        Sprite1a+1,a1             ; Address of sprite into a1
                       lea        Sprite1b+1,a3             ; Address of attached sprite
                       move.b     (a1),d1                   ; Sprite control into d1
                       move.b     #215,d2                   ; End of movement rhs of screen
                       move.b     #$40,d3                   ; Start of movement lhs

.1          
                       jsr        WaitRaster
    ;bsr        mwait
                       add.b      #1,d1                     ; Add 1 to sprite H
                       move.b     d1,(a1)                   ; Move into the control word
                       move.b     d1,(a3)                   ; Move into attached sprite control word
                       cmp.b      d2,d1                     ; Are we at the RHS of screen
                       bls        .1                        ; No, loop

              ; Update animation frame
              ; Copy control word from sprite 1 to sprite 2/3
                       lea        Sprite2a,a2               ; Sprite address
                       lea        Sprite2a+1,a1
                       move.b     d1,(a1)
    ;bsr        Setspriteframe       ; Set it
.2           
                       jsr        WaitRaster
   ; bsr        mwait
                       sub.b      #1,d1                     ; Subtract 1 from position
                       move.b     d1,(a1)                   ; Move into control work H
                       cmp.b      d3,d1                     ; Are we lower then LHS
                       bhi        .2                        ; No, loop

              ; Change sprite frame
                       lea        Sprite1a,a2               ; Sprite address
                       lea        Sprite1a+1,a1
                       move.b     d1,(a1)
   ; bsr        Setspriteframe       ; Set it

                       bra        .1                        ; Back to the start

AnimateSprite:
; Animate sprite routine. Animates a sprite
; Registers used
; d0 - Current sprite frame (0-15) and then offset
; d1 - number of sprites to skip
; d2 - Sprite address for swapping about
; d3 - Loop counter
; d4 - control word to copy in
; a0 - Sprite address from the copper
; a1 - Location of current sprite
; a2 - Control word to move into the next frame

                       movem.l    d0-d4/a0-a2,-(sp)

                       moveq      #1,d0
                       moveq      #0,d1
                       moveq      #0,d2
                       moveq      #0,d3

                       lea        spr_data,a2               ; Control word into d4
                       move.l     (a2),d4


              ; Get address of first sprite
                       move.b     #2-1,d3                   ; Num of sprites to make a frame
                       move.l     spr0copaddr,a0            ; Location of the first sprite in the copperlist ($0120xxxx)
                       move.b     spr_cur_frame,d0          ; What frame are we on?
                       move.w     #sprskip,d1               ; Number of sprites to skip
                       mulu       d0,d1                     ; offset
                       lea        Sprite1a,a1               ; address of first sprite

.1                     add.l      #$2,a0
                       add.l      d1,a1                     ; Point to the first sprite of the next frame
                       move.l     d4,(a1)                   ; Pop in new position to control word 
                       move.l     a1,d2                     ; Address of sprite
                       swap       d2                        ; Get the high word
                       move.w     d2,(a0)+                  ; Pop address into the copper
                       add.l      #$2,a0                    ; Get the low word
                       swap       d2
                       move.w     d2,(a0)+                  ; Pop into the copper and advance to next sprite pointer
                       move.l     #sprsize,d1               ; Size of 1 sprite


    ; Attached sprite 
                       bchg       #7,d4                     ; toggle the attached bit

                       add.l      #$2,a0                    ; Next sprite address
                       add.l      d1,a1                     ; Point to the first sprite of the next frame
                       move.l     d4,(a1)                   ; Pop in new position to control word 
                       move.l     a1,d2                     ; Address of sprite
                       swap       d2                        ; Get the high word
                       move.w     d2,(a0)+                  ; Pop address into the copper
                       add.l      #$2,a0                    ; Get the low word
                       swap       d2
                       move.w     d2,(a0)+                  ; Pop into the copper and advance to next sprite pointer
                       move.l     #sprsize,d1               ; Size of 1 sprite
                       bchg       #7,d4                     ; toggle the atached bit

                       add.l      #$00080000,d4             ; Sprite offset
                       dbf        d3,.1                     ; Loop to next sprite

                       addq       #1,d0

                ; Check if we are on the last frame, if so we go back to the first frame
                       cmp.b      #13,d0                                             
                       beq        .2                        ; Last frame, so we reset to 0
                       bra        .3                        ; Less than the last frame

.2                     move.l     #0,d0                     ; Back to frame 0
                
.3                     move.b     d0,spr_cur_frame          ; Save the frame counter                     
                       movem.l    (sp)+,d0-d4/a0-a2
                       rts


BLIT_PIPE:

; This routine blits the sprite at the correct x/y position

; Start with a simple A -> D blit: Trashes background but all is good

; Information needed
;
; Blit x position = mousex
; Blit y position = mousey
; Pipe piece to blit = currentpiece

; Window 320x256 (320/8=40 words)
; Pipe Sprites Window (416 x 32) = Thirteen 32x32 bobs
; Tile pieces are (for now) 32x32y = (32/8 = 4 Words)
; A Modulo will be 40-8 = 32 words
; D Modulo 
  
; BLTxPTH/L   - Input/Ouput data addresses
; BLTxDAT     - Data
; BLTxMOD     - Modulos
; BLTxFWM/LWM - Masks
; BLTCON0 / BLTCON1 - Control

; Set your bltcon regs first, 
; then your modulo regs, 
; then fwm/lwm, 
; then source and dest, 
; and finally set bltsize
 ;                      rts

 ; Input - 
 ; d3 - xpos
 ; d4 - ypos


; BLitter offsets, move to blitter function
BLITDMOD       equ (BITPLANE_WORDS*SCREEN_DEPTH)-(sprwidth/8)
PIPEBLIT       equ (PIPE_TILE_WIDTH-sprwidth)/8
;PIPEBLIT          equ (416-32)/8

                       movem.l    d0-d7/a0-a2,-(sp)

                       moveq      #5-1,d7                   ; For the loop

                       move.l     myimage_addr,a0           ; Pointer to image data
                       lea        pipetiles,a1              ; Pointer to sprite data

                       bsr        BlitterWait

  ; Set blitter registers
                       move.w     #$09f0,BLTCON0(a5)        ; A->D
                       move.w     #$0,BLTCON1(a5)
    

  ; Modulo for A (#SCREEN_WIDTH-#sprwidth)/8
                       move.w     #PIPEBLIT,d0
                       move.w     d0,BLTAMOD(a5)            ; Set the A source modulo

  ; Modulo for D (#SCREEN_WIDTH-#sprwidth)/8
                       move.w     #BLITDMOD,d0
                       move.w     d0,BLTDMOD(a5)            ; Set destination Modulo

  ; Set FwM/LWM
                       move.l     #$FFFFFFFF,BLTAFWM(a5)    ; Masking


  ; SpriteHeight*64 + (Spritewidth/16)
                       move.w     #sprheight<<6,d2          ; #sprheight*64 = 32*64 = 2048
                       move.w     #sprwidth>>4,d3           ; Spritewidth / 8 = 32/8 = 4BITPLANE_SIZE_B
                       add.w      d2,d3                     ; Result for blitsize in d3 

.loop 
  ; Pointers to data
                       bsr        BlitterWait  
                       move.l     a1,BLTAPTH(a5)            ; Source
                       move.l     a0,BLTDPTH(a5)            ; Dest
                       add.l      #SCREEN_WIDTH/8,a0        ; Next source Bitplane
                       add.l      #PIPE_SIZE_B,a1           ; Next pipe bitplane


  ; Work out blit size

                       move.w     d3,BLTSIZE(a5)    

                       dbf        d7,.loop
                       movem.l    (sp)+,d0-d7/a0-a2
                       rts

MASK_BOB:
masklplw:
                       move.l     d3,d1
                       sub.l      #1,d1
masklpln:

;or 5 bpl into one w
                       move.l     #0,d4
                       move.w     (a2,d4),d2                ;1
                       add.l      d3,d4
                       add.l      d3,d4
                       or.w       (a2,d4),d2                ;2
                       add.l      d3,d4
                       add.l      d3,d4
                       or.w       (a2,d4),d2                ;3
                       add.l      d3,d4
                       add.l      d3,d4
                       or.w       (a2,d4),d2                ;4
                       add.l      d3,d4
                       add.l      d3,d4
                       or.w       (a2,d4),d2                ;5

;write mask to 5 planes
                       move.l     #0,d4
                       move.w     d2,(a1,d4)                ;1
                       add.l      d3,d4
                       add.l      d3,d4
                       move.w     d2,(a1,d4)                ;2
                       add.l      d3,d4
                       add.l      d3,d4
                       move.w     d2,(a1,d4)                ;3
                       add.l      d3,d4
                       add.l      d3,d4
                       move.w     d2,(a1,d4)                ;4
                       add.l      d3,d4
                       add.l      d3,d4
                       move.w     d2,(a1,d4)                ;5

                       add.l      #2,a1                     ;next w
                       add.l      #2,a2
                       dbf        d1,masklpln

;next row add 4width2 bytes (width is in w)
                       move.l     d3,d4
                       lsl.l      #3,d4
                       add.l      d4,a1
                       add.l      d4,a2

                       dbf        d0,masklplw
                       rts



BLIT_PIPE_I:

; This routine blits the sprite at the correct x/y position
; **** Uses interleaved assets
; Full cookie-cut blit

; A - Source
; B - Mask
; C - Background
; D - Dest

; Cookiecut mode: $
 ; Input - 
 ; d0 - xpos
 ; d1 - ypos
 ; d2 - shift value

 ; a0 - Source
 ; a1 - Dest
 ; a2 - Mask
; 32x32 Pipe info

;PIPE_TILE_WIDTH  equ 416
;PIPE_TILE_HEIGHT equ 32
;PIPE_TILE_WORDS  equ PIPE_TILE_WIDTH/8
;PIPE_SIZE_B      equ PIPE_TILE_WORDS*PIPE_TILE_HEIGHT
;PIPE_DEPTH       equ 5

; Game screen info
;SCREEN_WIDTH     equ 320
;SCREEN_HEIGHT    equ 256
;BITPLANE_SIZE    equ SCREEN_WIDTH/8
;SCREEN_DEPTH     equ 5
;BITPLANE_SIZE_B  equ (BITPLANE_SIZE*SCREEN_HEIGHT)

; Each sprite is composed of 2 sprites attached (4 sprites for each frame). Each half sprite is $160 bytes (352 bytes Decimal)
; Therefore each sprite is $160*4 

;sprheight        equ 32
;sprwidth         equ 32
;sprsize          equ (sprheight*4)+8                                                                                                      ; Bytes to skip to next sprite (sprheight*bytesperline+controlwords)
;sprskip          equ sprsize*4

BOBWIDTH       equ 32+16                                    ; Our bob is 32px wide with 16 px for shifting
BOBHEIGHT      equ 32

; BLitter offsets modulo's, move to blitter function
GAMESCREEN_MOD equ BITPLANE_WORDS-(BOBWIDTH/8)
PIPESOURCE_MOD equ PIPE_TILE_WORDS-(BOBWIDTH/8)

; Calculate blitsize
; Spriteheight*bitplanes*64 + spritewidth*bitplanes/8
blitsize       equ (BOBHEIGHT*SCREEN_DEPTH*64)+BOBWIDTH/16
yblit          equ BITPLANE_WORDS*SCREEN_DEPTH

                       movem.l    d0-d7/a0-a2,-(sp)
                       add.w      d0,d0                     ; correct x pos to blit to
                      ; and.w      #%1111111111100000,d0
    ;and.w    #%1111111111100000,d1
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

; This routine creates the shift values. D0 should contain the position to blit to. 
;  move.w d0,d2
;  and.w #15,d2
;  ror.w #4,d2
;  or.w #$fca,d2
;  move.w  d2,shift_Val
;  swap d2
;  move.l d0,BLTCON0(a6)
  
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

                       move.l     myimage_addr,a1           ; Pointer to image data (D)

                       mulu       #yblit,d1                 ; Screen_Width_Bytes * Num_Planes * Coord_Ypos
             
                       asr.w      #3,d0                     ; Convert to words
                       add.l      d0,d1                     ; Add x and y together 
                       add.l      d1,a1                     ; move to image offset

                       lea        pipetiles_inter,a0        ; Pointer to bob data (A)
                       add.l      #16,a0                     ; point to the next sprite
                       lea        pipemask,a2               ; Pointer to mask (B)
                       add.l      #8,a2

                       bsr        BlitterWait

  ; Set blitter registers
                       move.w     #$bFCA,BLTCON0(a5)        ; Cookiecut with shifting
                       move.w     #$b000,BLTCON1(a5)           
    

  ; Modulo for A Mask and B Tiles (#SCREEN_WIDTH-#sprwidth)/8
                       move.w     #PIPESOURCE_MOD,d4
                       move.w     d4,BLTAMOD(a5)            ; Set the source A Mask modulo
                       move.w     d4,BLTBMOD(a5)            ; Source modulo
  

  ; Modulo for C and D (#SCREEN_WIDTH-#sprwidth)/8
                       move.w     #GAMESCREEN_MOD,d4
                       move.w     d4,BLTCMOD(a5)            ; Source gamescreen
                       move.w     d4,BLTDMOD(a5)            ; Set destination Modulo

  ; Set FwM/LWM
                       move.w     #$ffff,BLTAFWM(a5)        ; Masking
                       move.w     #$0000,BLTALWM(a5)
    

  ; Blitsize
                       move.w     #blitsize,d3              ; Spritewidth / 8 = 32/8 = 4

  ; Pointers to data
                       bsr        BlitterWait  
                       move.l     a2,BLTAPTH(a5)            ; Mask             
                       move.l     a0,BLTBPTH(a5)            ; Source
                       move.l     a1,BLTCPTH(a5)
                       move.l     a1,BLTDPTH(a5)            ; Dest

  ; Aaaand blit
                       move.w     d3,BLTSIZE(a5)    


                       movem.l    (sp)+,d0-d7/a0-a2
                       rts


coord_x:
                       dc.w       0
coord_y:
                       dc.w       0
shift_Val:
                       dc.w       0

Sprite_Structures:

; Each structure gives the info related to a pipe piece

; Cross enter left to right
crosslr_ID             dc.b       0                         ; Sprite ID number
crosslr_X              dc.w       0                         ; X pos on grid
crosslr_y              dc.w       0                         ; Y pos on grid
crosslr_sprite_number  dc.w       0
crosslr_anim_frames    dc.b       1,2,3,4,5,6
crosslr_full           dc.b       0                         ; Set to 1 if it is the second pass through
crosslr_oneway         dc.b       0                         ; set to 1 if it is one way


; Cross enter right to left




                       even