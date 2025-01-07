; The plugin isn't activating on breakpoints I set in some included files.

; Lets set some breakpoints

; This is simply the loader code that is assembled

;  include    "Src/startup.s"
; Overflow - 2021 - Mark Green
; 
; Initial Design and test stages - April 2021
; Restarted - 19 Jan 2022

; Hardware offsets
ENABLE_DEBUG:          equ         1                              ; Added by mcgeezer

                       jmp        ProgStart
; Base custom address
                       incdir     "include"
                       include    "funcdef.i"
                       include    "i/custom.i"
                       include    "exec/types.i"
                       include    "exec/exec.i"
                       include    "exec/exec_lib.i"
                       include    "libraries/dos.i"
                       include    "libraries/dos_lib.i"
                       include    "graphics/gfxbase.i"
                       include    "graphics/graphics_lib.i"

; My includes                       
                       ;include    "src/Constants.asm"
                       include    "Startup.i"
                       include    "src/Copper.asm"
                       include    "src/Functions.asm"
                       include    "src/Joy.asm"
                       include    "src/Mouse.asm"
                       include    "src/debug.asm"
                       Include    "src/Sprite_Functions.asm"  
                       include    "src/Main.asm"


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

       jmp        ProgStart    