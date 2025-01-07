		; Routine ReadInput
		; From Roondar / eab.abime.net, reads joystick port 2
		; and checks left & right mouse buttons.
		;
		; Adapted slightly:
		;	- changed result table
		;	- reset potgo at end of read
		;	- conversion table renamed and moved into data section
		;	- changed registers used and cleared result register on call
		;
		; Result table:
		;	Up			-	   1
		;	Down		-	   2
		;	Left		-	   4
		;	Right		-	   8
		;	Fire 1		-	 256
		;	Fire 2		-	 512
		;	Left mouse	-	1024
		;	Right mouse	-	2048
		; Multiple directions/buttons are or'd together
		;
		; A5: custombase
		; Returns
		; D7: joystick/left mouse button value
        
custombase  EQU $dff000
ciaa        EQU $bfe001
ciab        EQU $bfe000
potgor      EQU $016
pra         EQU $0
bit_joyb1   EQU 7
bit_joyb2   EQU 14
bit_mouseb1 EQU 6
bit_mouseb2 EQU 10

ReadInput
          movem.l    a0/a3,-(sp)                         ; Stack
          lea.l      ciaa,a0
          moveq      #0,d7

          btst       #bit_joyb2&7,POTGOR(a5)
          seq        d7
          add.w      d7,d7

          btst       #bit_joyb1,pra(a0)
          seq        d7
          add.w      d7,d7

          move.w     JOY1DAT(a5),d6
          ror.b      #2,d6
          lsr.w      #6,d6
          and.w      #%1111,d6
          lea.l      joystick,a3
          move.b     0(a3,d6.w),d7
		
		; Read left mouse button
          btst       #bit_mouseb1,pra(a0)
          bne        .rmb
		
          bset       #10,d7
		
		; Read right mouse button
.rmb      btst       #bit_mouseb2,potgor(a5)
          bne        .done
		
          bset       #11,d7
			
		; Reset 2nd buttons for next call
.done     move.w     #$cc00,POTGO(a5)
          movem.l    (sp)+,a0/a3                         ; Stack
          rts

			; Joystick conversion values
joystick  dc.b       0,2,10,8,1,0,8,9,5,4,0,1,4,6,2,0
          cnop       0,2