FONT_WIDTH:           equ        (624/8)*1
DEBUG_SCREEN_SIZE_X:  equ        40
TXTLEN_WORD:          equ        3
TXTLEN_LWORD:         equ        7

DEBUG_SERIAL:         equ        0

hAddress:             equ        0

DEBUG_SCREEN_PTR:     dc.l       DEBUG_SCREEN
DEBUG_SCREEN:         dc.l       0

; Steps to install

; 1) Allocate 2048 bytes of chip ram for the debug screen display (6 lines of text)

; 2) Setup the copper to display the returned memory pointer for the display.
		
; Call this every frame to update
agdDebugWindow:       movem.l    d0-d7/a0-a3,-(a7)
		
                      moveq      #0,d0
                      lea        DEBUG_VARS,a3
; Do Words
                      rept       6
                      move.l     (a3)+,d0                            ; Get X Position
                      move.l     d0,d2
                      move.l     (a3)+,d1                            ; Get Y Position
                      move.l     DEBUG_SCREEN_PTR,a1                 ; Screen Address
                      move.l     hAddress(a1),a1
                      move.l     (a3)+,a0                            ; Get Text Pointer

                      bsr        agdDebugText                        ; Draw Text in a0
                      lea        TXT_WORD,a0                         ; Buffer for word in
                      move.l     (a3)+,a2                            ; Pointer to value
                      move.w     (a2),d0                             ; Dereference
                
                      moveq      #TXTLEN_WORD,d7                     ; size of a word
                      bsr        agdHexToAscii                       ; convert it
                      move.l     d2,d0
                      addq.w     #7,d0                               ; Index to the Right of the text
                      lea        TXT_WORD,a0                         ; Print the converted word
                      move.l     DEBUG_SCREEN_PTR,a1
                      move.l     hAddress(a1),a1
                      bsr        agdDebugText
                      endr

; Do Lwords
                      rept       6
                      move.l     (a3)+,d0                            ; Get X Position
                      move.l     d0,d2
                      move.l     (a3)+,d1                            ; Get Y Position
                      move.l     DEBUG_SCREEN_PTR,a1                 ; Screen Address
                      move.l     hAddress(a1),a1
                      move.l     (a3)+,a0                            ; Get Text Pointer

                      bsr        agdDebugText                        ; Draw Text in a0
                      lea        TXT_LWORD,a0                        ; Buffer for word in
                      move.l     (a3)+,a2                            ; Pointer to value
                      move.l     (a2),d0                             ; Dereference
                
                      moveq      #TXTLEN_LWORD,d7                    ; size of a word
                      bsr        agdHexToAscii                       ; convert it
                      move.l     d2,d0
                      addq.w     #7,d0                               ; Index to the Right of the text
                      lea        TXT_LWORD,a0                        ; Print the converted word
                      move.l     DEBUG_SCREEN_PTR,a1
                      move.l     hAddress(a1),a1
                      bsr        agdDebugText
                      endr
		
		;COL0_BLACK

.exit:                movem.l    (a7)+,d0-d7/a0-a3
                      rts

;d0=word
;a0=text pointer
;d7=length 3=Word 7=LWORD
agdHexToAscii:
                      movem.l    d0-d1,-(a7)
                      clr.b      1(a0,d7)                            ; Safe terminate
.loop:                move.b     d0,d1
                      and.b      #$f,d1
                      cmp.b      #10,d1
                      bge.s      .alpha
                      add.b      #48,d1
                      bra.s      .num
.alpha:               add.b      #55,d1
.num:                 move.b     d1,(a0,d7)
                      lsr.l      #4,d0
                      dbf        d7,.loop
                      movem.l    (a7)+,d0-d1
                      rts

; d0=8x8 X Char position (0 to 38)
; d1=8x8 Y Char position (0 to depth)
; a0=text
; a1=Debug Screen Origin
agdDebugText:
                      movem.l    d0-d1/a0-a3,-(a7)
                      add.l      d0,a1                               ; Index to X Position
		
                      lea        32.w,a3
                      lsl.w      #3,d1                               ; Multiply 8x8 Block to Pixel Position		

                      move.l     d1,d0                               ; mulitply d1 by 40 (screen size)
                      lsl.w      #3,d0                               ; 1=8
                      lsl.w      #5,d1                               ; 1=32
                      add.l      d0,a1                               ; 8+32=40
                      add.l      d1,a1                               ; Index to Y Position
		
.loop:                moveq      #0,d0
                      lea        DEBUG_FONT,a2
                      move.b     (a0)+,d0
                      beq.s      .exit
                      sub.l      a3,d0
                      lsl.w      #3,d0

                      add.l      d0,a2                               ; index into character

                      move.b     (a2)+,(a1)
                      move.b     (a2)+,DEBUG_SCREEN_SIZE_X*1(a1)
                      move.b     (a2)+,DEBUG_SCREEN_SIZE_X*2(a1)
                      move.b     (a2)+,DEBUG_SCREEN_SIZE_X*3(a1)
                      move.b     (a2)+,DEBUG_SCREEN_SIZE_X*4(a1)
                      move.b     (a2)+,DEBUG_SCREEN_SIZE_X*5(a1)
                      move.b     (a2)+,DEBUG_SCREEN_SIZE_X*6(a1)
                      addq.w     #1,a1
                      bra.s      .loop
.exit:                movem.l    (a7)+,d0-d1/a0-a3
                      rts


; Call this routine 
agdCreateDebugCopper:
                      move.l     #$f007fffe,(a0)+
		
                      move.l     #COLOR01<<16+$0707,(a0)+
                      move.l     #BPLCON0<<16+0200,(a0)+
			
                      move.w     #BPLCON0,(a0)+
                      move.w     #$1200,(a0)+
                      move.w     #BPLCON1,(a0)+  
                      move.w     #0,(a0)+            
                      move.w     #BPL1MOD,(a0)+
                      move.w     #0,(a0)+               
                      move.w     #BPL2MOD,(a0)+
                      move.w     #0,(a0)+               

                      move.l     DEBUG_SCREEN_PTR,a1
                      move.l     hAddress(a1),d0
		
                      move.w     #BPL0PTL,(a0)+
                      move.w     d0,(a0)+
                      swap       d0
                      move.w     #BPL0PTH,(a0)+
                      move.w     d0,(a0)+
                      rts
		
DEBUG_NULL:           dc.l       0

; Change these vars below to what you like and set ENABLE_DEBUG in main to 1
DEBUG_VARS:           dc.l       0,0,DEBUG_TXT_WORD1,mouse_x
                      dc.l       13,0,DEBUG_TXT_WORD2,mouse_y
                      dc.l       26,0,DEBUG_TXT_WORD3,shift_Val
                      dc.l       0,1,DEBUG_TXT_WORD4,DEBUG_NULL
                      dc.l       13,1,DEBUG_TXT_WORD5,DEBUG_NULL
                      dc.l       26,1,DEBUG_TXT_WORD6,DEBUG_NULL
                      dc.l       0,2,DEBUG_TXT_LWORD1,DEBUG_NULL
                      dc.l       18,2,DEBUG_TXT_LWORD2,DEBUG_NULL
                      dc.l       0,3,DEBUG_TXT_LWORD3,DEBUG_NULL
                      dc.l       18,3,DEBUG_TXT_LWORD4,DEBUG_NULL
                      dc.l       0,4,DEBUG_TXT_LWORD5,DEBUG_NULL
                      dc.l       18,4,DEBUG_TXT_LWORD6,DEBUG_NULL

DEBUG_TXT_WORD1:      dc.b       "MOUSEX",0
                      even
DEBUG_TXT_WORD2:      dc.b       "MOUSEY",0
                      even
DEBUG_TXT_WORD3:      dc.b       "SHIFTV",0
                      even
DEBUG_TXT_WORD4:      dc.b       "THMDIR",0
                      even
DEBUG_TXT_WORD5:      dc.b       "BSHITS",0
                      even
DEBUG_TXT_WORD6:      dc.b       "BSTIMR",0
                      even
DEBUG_TXT_LWORD1:     dc.b       "BOSS2X",0
                      even
DEBUG_TXT_LWORD2:     dc.b       "HITPOS",0
                      even
DEBUG_TXT_LWORD3:     dc.b       "CHIPRM",0
                      even
DEBUG_TXT_LWORD4:     dc.b       "FASTRM",0
                      even
DEBUG_TXT_LWORD5:     dc.b       "FINERL",0
                      even
DEBUG_TXT_LWORD6:     dc.b       "FINERR",0
                      even
				
TXT_WORD:             ds.b       8,0
                      even
		
TXT_LWORD:            ds.b       8,0
                      even
						
DEBUG_FONT:           incbin     "data/debug_font_8x8.iff"
                      even
			