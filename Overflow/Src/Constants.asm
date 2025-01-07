; Constants

; 32x32 Pipe info
PIPE_TILE_WIDTH  equ 416                                     ; Width of whole spritesheet
PIPE_TILE_WORDS  equ PIPE_TILE_WIDTH/8
PIPE_TILE_HEIGHT equ 32
PIPE_SIZE_B      equ PIPE_TILE_WORDS*PIPE_TILE_HEIGHT
PIPE_DEPTH       equ 5

; Game screen info
SCREEN_WIDTH     equ 320
SCREEN_HEIGHT    equ 256
SCREEN_DEPTH     equ 5                           ; 5 Planes

; Bitplane info
BITPLANE_WORDS   equ SCREEN_WIDTH/8
BITPLANE_SIZE_B  equ (BITPLANE_WORDS*SCREEN_HEIGHT)

; Each sprite is composed of 2 sprites attached (4 sprites for each frame). Each half sprite is $160 bytes (352 bytes Decimal)
; Therefore each sprite is $160*4 

sprheight        equ 32
sprwidth         equ 32
sprsize          equ (sprheight*4)+8                                                                                                      ; Bytes to skip to next sprite (sprheight*bytesperline+controlwords)
sprskip          equ sprsize*4

SPRxSPD          equ 1
SPRySPD          equ 2
