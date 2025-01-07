; My basic startup routines.
; Registers
;
; a5 = Custom ($Dff000)
; a6 = Execbase ($4)

Setup:

         move.l    $4,a6                         ; execbase
         lea       $DFF000,a5                    ; custom base
	
; Allocate ram for copperlist
         move.l    #1024,d0
         move.l    #MEMF_CHIP,d1
         jsr       _LVOAllocMem(a6)
         move.l    d0,copperlist                 ; save copperlist address
	
; Load gfx library first and get the system copperlist
         clr.l     d0                            ; any version
         move.l    #gfxname,a1                   ; gfx library
         jsr       _LVOOpenLibrary(a6)           ; openlibrary
         tst.l     d0                            ; base address, or 0 for failure
         beq       exit
         move.l    d0,gfxbase                    ; save gfx lib base address
	
; Save the system copperlist
         move.l    d0,a1                         ; Gfxlib base address
         move.l    old_Clist1_off(a1),sys1cop    ; save the copperlist
         move.l    old_Clist2_off(a1),sys2cop
         move.l    old_View_off(a1),sysview
         rts


; Take system routines
takesys:

	; Backup our system
         move.w    DMACONR(a5),d0
         or.w      #$8000,d0
         move.w    d0,dmasys
	
         move.w    ADKCONR(a5),d0
         or.w      #$8000,d0
         move.w    d0,adksys
	
         move.w    INTENAR(a5),d0
         or.w      #$8000,d0
         move.w    d0,intsys
	
         move.w    INTREQR(a5),d0
         or.w      #$8000,d0
         move.w    d0,intrqs
	
         move.w    #$138,d0                      ;wait for EOFrame
         bsr.w     WaitRaster

	; Turn off multitasking
	
         jsr       forbid(a6)

	; Take the system
	
         move.w    #$7fff,DMACON(a5)
         move.w    #$7fff,INTENA(a5)
         move.w    #$7fff,INTREQ(a5)
	
         rts


dmasys:  dc.l      0                             ; dma
adksys:  dc.l      0                             ; ADKconR
intsys:  dc.l      0                             ; Intenar
intrqs:  dc.l      0                             ; Intreq
