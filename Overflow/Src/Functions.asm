; This source code will contain various misc functions.

; -- Blitter functions

; Wait for the blitter to finish; assumes base offset is in a5


BlitterWait:
     tst        DMACONR(a5)
.waitblit
     btst       #6,DMACONR(a5)
     bne.s      .waitblit
     rts

; Wait for the top of the frame
WaitRaster:
     movem.l    d1-d2/a0,-(sp)    ; Preserve registers
     move.l     #$1ff00,D2
     lsl.l      #8,d0
     and.l      d2,d0
     lea        $dff004,a0
.wr  move.l     (a0),d1
     and.l      d2,d1
     cmp.l      d1,d0
     bne.s      .wr
     movem.l    (sp)+,d1-d2/a0    ; Restore registers
     rts