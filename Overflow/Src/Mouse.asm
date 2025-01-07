InitMouse:
; Mouse routine

; set the starting mouse position (for example 0,0)
             move.w    #0,mouse_x
             move.w    #0,mouse_y

; initialize the old counters, so the mouse will not jump on first movement
             move.w    $dff00a,d0
             move.b    d0,oldhorizcnt
             lsr.w     #8,d0
             move.b    d0,oldvertcnt

             rts                         ; return from subroutine - exit program

MouseEventHandler:
             move.w    $dff00a,d1
             move.w    d1,d0
             sub.b     oldhorizcnt,d0
             ext.w     d0
             add.w     d0,mouse_x
             move.b    d1,oldhorizcnt
             lsr.w     #8,d1
             move.b    oldvertcnt,d0
             move.b    d1,oldvertcnt
             sub.b     d0,d1
             ext.w     d1
             add.w     d1,mouse_y
             rts

mouse_x:
             dc.w      0
             even
mouse_y:
             dc.w      0
             even
oldhorizcnt:
             ds.b      1
             even
oldvertcnt:
             ds.b      1
             even