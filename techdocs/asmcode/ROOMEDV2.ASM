;----------------------------------------------------------------
;       ENHANCED STATICS ROOM EDITOR V2.0
;       by Francois Blanchette
;----------------------------------------------------------------

EXTERN CLS:PROC
EXTERN DES_EXT:WORD
EXTERN EXT:PROC
EXTERN FILENAME:WORD
EXTERN GETAX:PROC
EXTERN LIB_EXT:WORD
EXTERN LIBTEMP:WORD
EXTERN LOADNEW:PROC
EXTERN LOADOLD:PROC
EXTERN MAKEPATH:PROC
EXTERN NOT_FOUND:PROC
EXTERN OLD_VIDEO_MODE:WORD
EXTERN QUIT:PROC
EXTERN TEMPDX:WORD
EXTERN SENDERRORMESSAGE:PROC
EXTERN SCR_EXT:WORD
EXTERN SCRIPTDATA:WORD
EXTERN SCRIPT_COMPILER:PROC
EXTERN STATUS_TABLE:WORD
EXTERN VIDEOSWITCH:PROC
EXTERN DRAW_SCREEN:PROC
EXTERN DRAW_SCREENV1_1:PROC
EXTERN REDRAW_SCREEN:PROC
EXTERN RESETSEQUENCE:PROC
EXTERN MX:WORD
EXTERN MY:BYTE
EXTERN SHOWSSFS:BYTE

PUBLIC PATH
PUBLIC CONVENSIONS
Public ROOM_NAMES

;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------

;----------------------------------------------------------------
DATA      SEGMENT PUBLIC  'DATA'

COPYRIGHT      	db "STATICS ROOM EDITOR V2.0: (C) 1994 FRANCOIS BLANCHETTE"
PATH	       	db "c:\pathcw\",0
CREATSCRIPTFAILTEXT db"Fatal: Unable to creat script file.$"
READERROROCCUREDTEXT db"Fatal: Read error occured.$"
OVERWRITESCRIPTFAILTEXT db"Fatal: Disk error occured.$"
OVERWRITESCRIPT db "Overwrite existing script file? (Y/N)$"
RESET_TEXT      db "Reset program? (Y/N)$"
PAUSE_TEXT     	db "Press [space] to continue playing...    $"
OBJNAMES_PAT   	db "OBJNAMES.PAT",0
STATICS_MSQ    	db "STATICS.MSQ",0
TESTFILE_CMP   	db "TESTFILE.CMP",0
GIVELIBNAMETEXT db "Enter librairy name:$"
SELECTOPTIONTEXT db 13,10
		db "Please select an option:",13,10,13,10
		db "L)oad a room",13,10
		db "C)reat room",13,10,13,10,"$"
LOADROOMTEXT	db "Load room:$"
CREATROOMTEXT	db "Creat room:$"
ASCII_TABLE     db " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"
		db "#$%&*().!,/?:;+-{}[]\|`~<>1234567890",0,-1

WHICHLIB	db "LIBRAIRY OBJ:"
LIBOBJNUM	db 0,0,0,0,0
WHICHSCR	db "SCRIPT ENTRY:"
SCRNUMBER	db 0,0,0,0,0

align 4
ASCII		db 6000 DUP (0)
TEMPBUFNAME    	db 9,0
		db 16 DUP (0)
		db "$"

ABSXPOS		db 0,0
SCREENX1	db 0,0
SCREENX2	db 0,0
COLOR		db 0

DESCRIPTIONS_TABLE db 8192 DUP (0)

align 2

SCRIPTPOINTER	dw 0
SCRIPTNOE 	dw 0
SCRIPTPOE	dw 0

LIBPOINTER	dw 0
LIBNOE		dw 0
LIBPOE		dw 0

Room_Names 	db 0

DATA   ENDS
;----------------------------------------------------------------

FONTS SEGMENT PUBLIC 'FONTS'
FONTS ENDS

LIBRAIRY SEGMENT PUBLIC 'LIBRAIRY'
LIBRAIRY ENDS

STATICS SEGMENT PUBLIC 'STATICS'
STATICS ENDS

STATICS2 SEGMENT PUBLIC 'STATICS2'
STATICS2 ENDS

SCREEN SEGMENT PUBLIC 'SCREEN'
SCREEN ENDS

;----------------------------------------------------------------
CODE SEGMENT READONLY PUBLIC 'CODE'
VLAMITS  PROC NEAR
;----------------------------------------------------------------
.386

		; AFFICHE OPTIONS
		;
		; Please select an option:
		; L)oad a room
		; C)reat a room

		call VIDEOSWITCH

                call Convensions
                mov byte ptr SHOWSSFS,0

RESTART:        mov dx,0a000h
		mov gs,dx
		call CLS
		call CLEAR_LOCALS

                ;--------------------------------------------------------

		; LOAD STATICS.MSQ
		;mov dx,DATA
		;mov ds,dx
		;mov es,dx
		;mov dx,offset STATICS_MSQ
		;mov bx,offset ASCII
		;mov cx,5831
		;call LOADOLD

LOADSTATICS_MSQ:
                call Convensions
		mov bp,offset ASCII_TABLE
                mov di,offset ASCII
NextChar:       push di

                ; Place le curseur à (0,0)
                mov bh,0
                mov dx,0
                mov ah,2
                int 10h

                call Convensions
                mov si,bp
                mov al,[si]
                cmp al,-1
                je LastChar
                inc bp

                ; Affiche un character
		mov bl,15
                mov ah,0eh
                int 10h

                pop di
                mov si,0

                call Convensions
                mov cx,8
Tchar:          mov eax,gs:[si]
                mov [di],eax
                mov eax,gs:[si+4]
		mov [di+4],eax
                add si,140h
                add di,8
                loop Tchar
                jmp NextChar
LastChar:
                ;---------------------------------------------------------

		; PLACE CURSOR POSITION
		mov ah,2
		mov bh,0
		mov dx,0
		int 10h

		; SELECT OPTION TEXT
		mov dx,DATA
		mov ds,dx
		mov dx,offset SELECTOPTIONTEXT
		mov ah,9
		int 21h

READKEYBOARD:	call GETAX
		call CONVENSIONS
		cmp al,"l"
		je LOADROOM
		cmp al,"c"
		je CREATROOM
		jmp READKEYBOARD

		;---------------------------------------------------

LOADROOM:       mov dx,offset LOADROOMTEXT	; Print text about loading
		mov ah,9                        ; a room with a dos
		int 21h                         ; fonction call.
		call INPUTFILENAME              ; Input a filename

READROOM_DISK:	call CONVENSIONS                ; Add a lib extension to
		mov si,offset TEMPBUFNAME       ; filename
		mov bl,[si+1]
		mov bh,0

		mov si,offset LIB_EXT
		mov di,offset TEMPBUFNAME+2
		add di,bx
		call EXT
		mov dx,DATA                     ; Read librairy's header
		mov ds,dx                       ; into LIBTEMP buffer.
		mov es,dx
		mov dx,offset TEMPBUFNAME+2
		mov bx,offset LIBTEMP
		mov cx,4
		call LOADNEW
		call CONVENSIONS

		mov ah,3dh			; Open a read-only access
		; modification
		mov dx,offset FILENAME          ; to librairy
		mov al,0
		int 21h
		jc READERROROCCURED
		mov bp,ax              		; Store access code to
		mov bx,ax                       ; librairy in BP.

		call CONVENSIONS        	; Read librairy definitions
		mov ah,3fh                      ; into memory buffer.
		mov si,offset LIBTEMP
		mov cx,[si+2]
		mov dx,LIBRAIRY
		mov ds,dx
		mov dx,0			; CORRECTION
		int 21h
		jc READERROROCCURED

		mov bx,bp               	; Read fonts definions
		call CONVENSIONS                ; from librairy on disk
		mov ah,3fh                      ; into RAM.
		mov si,offset LIBTEMP
		mov cx,[si]
		rol cx,6
		mov dx,FONTS
		mov ds,dx
		mov dx,0			; CORRECTION
		int 21h
		jc READERROROCCURED

		mov bx,bp                       ; Close all access to
		mov ah,3eh                      ; librairy.
		int 21h
		jc READERROROCCURED

		;-------------------------------

		call CONVENSIONS
		mov si,offset TEMPBUFNAME       ; Add a .SCR extension
		mov bl,[si+1]                   ; to filename.
		mov bh,0

		mov si,offset SCR_EXT
		mov di,offset TEMPBUFNAME+2
		add di,bx
		call EXT

		mov dx,DATA                     ; Read script file into
		mov ds,dx                       ; RAM.
		mov es,dx
		mov dx,offset TEMPBUFNAME+2
		mov bx,offset SCRIPTDATA
		mov cx,8192
		call LOADNEW

		;-------------------------------

		call CONVENSIONS
		mov si,offset TEMPBUFNAME       ; Add a .DES extension
		mov bl,[si+1]                   ; to filename.
		mov bh,0

		mov si,offset DES_EXT
		mov di,offset TEMPBUFNAME+2
		add di,bx
		call EXT

		mov dx,DATA                     ; Read description file into
		mov ds,dx                       ; RAM.
		mov es,dx
		mov dx,offset TEMPBUFNAME+2
		mov bx,offset DESCRIPTIONS_TABLE
		mov cx,8192
		call LOADNEW

		jmp SETUP_PART01

		;----------------------------------------------

CREATROOM:	mov dx,offset CREATROOMTEXT
		mov ah,9
		int 21h
		call INPUTFILENAME

		call CONVENSIONS                ; Add a lib extension to
		mov si,offset TEMPBUFNAME       ; filename
		mov bl,[si+1]
		mov bh,0

		mov si,offset SCR_EXT
		mov di,offset TEMPBUFNAME+2
		add di,bx
		call EXT

		call CONVENSIONS
		mov dx,offset TEMPBUFNAME+2
		call MAKEPATH
		call CONVENSIONS

		mov dx,offset FILENAME   	; Creat a blank SCRipt
		mov ah,3ch                      ; file.
		mov cx,0
		int 21h
		jc CREATSCRIPTFAIL

		mov bx,ax
		mov bp,ax

		;mov ah,40h
		;mov cx,0
		;int 21h
		;jc CREATSCRIPTFAIL

		mov bx,bp
		mov ah,3eh
		int 21h
		jc CREATSCRIPTFAIL
		jmp READROOM_DISK

		;------------------------------------------------------
		; ////////////////////////////////////////////////////
		;------------------------------------------------------

SETUP_PART01:   call SCRIPT_COMPILER
		call CONVENSIONS
		call CLS

		;------------------------------------------------------
		; ////////////////////////////////////////////////////
		;------------------------------------------------------

		mov si,offset SCRIPTDATA
CHKSCRDIM:	mov al,[si]
		cmp al,0
		je SCRDIMFOUND
		add si,4
		jmp CHKSCRDIM

SCRDIMFOUND:    mov di,offset SCRIPTNOE
		sub si,offset SCRIPTDATA
		shr si,2
		mov [di],si
		mov di,offset SCRIPTPOE
		mov [di],si

		mov bx,0
		mov si,4			; MODIFICATION 30 MARS 1994
CHKLIBEND:	mov al,fs:[si]
		cmp al,0
		je LIBENDFOUND
		mov si,fs:[si+6]
		inc bx
		jmp CHKLIBEND

LIBENDFOUND:    mov di,offset LIBNOE
		mov [di],bx

		;//////////////////////////
		; ***** SETUP SCREEN *****
		;//////////////////////////

		;call DRAW_SCREEN		; Use EXTERNAL dynamic draw
		call CONVENSIONS		; Reset segments

		call ADJSCRIPTPOINTER
		call READSCREENXY
DOITAGAIN:	call ADJSCREENXY_MX
		call DRAW_SCREENV1_1
		call SHOWIDCODE
		call WRITEDESCSEQ

		mov dx,SCREEN
		mov fs,dx
		mov dx,0a000h
		mov gs,dx

		mov cx,65536/4
		mov si,4
REDHAIR:	mov eax,fs:[si]
		mov gs:[si],eax
		add si,4
		loop REDHAIR

		call DRAWMOVABLEIMAGE
MAIN_LOOP:      call DRAWBORDERS
		call GETAX
		call CONVENSIONS

		cmp al,"8"
		je OBJUP
		cmp al,"2"
		je OBJDN
		cmp al,"4"
		je OBJLF
		cmp al,"6"
		je OBJRG
		cmp al,13
		je ADDTOSCRIPT
		cmp al,"n"
		je INCIMA
		cmp al,"b"
		je DECIMA
		cmp al,"="
		je SAVESCR
		cmp ah,61
		je BEFORE
		cmp ah,62
		je AFTER
		cmp ah,63
		je FIRSTENTRY
		cmp ah,64
		je LASTENTRY
		cmp al,9		; TAB
		je RESETPROG

		jmp MAIN_LOOP


; WRITE A DESCRIPTOR SEQ

WRITEDESCSEQ:	mov dx,SCREEN
		mov gs,dx

		mov di,0a00h*22
		mov si,offset LIBPOE
		mov cl,[si]
		mov ch,0

		mov si,offset DESCRIPTIONS_TABLE
		cmp cx,0
		je DESPOINTERFOUND

LOOKFORBLANK:	mov al,[si]
		inc si
		cmp al,13
		jne LOOKFORBLANK
		loop LOOKFORBLANK

DESPOINTERFOUND:mov al,[si]
		cmp al,13
		je ENDOFDESC_ENTRY

		inc si
		push si

		mov si,offset ASCII_TABLE
LOOKAGG:	cmp al,[si]
		je MATCH_XXY
		inc si
		jmp LOOKAGG

MATCH_XXY:	sub si,offset ASCII_TABLE
		rol si,6
		add si,offset ASCII

		push di

		mov bx,8
PRNA2:		mov cx,4

PRNA1:		mov al,[si]
		cmp al,15
		jne PRNA3
		dec al
PRNA3:		mov gs:[di],al
		inc si
		inc si
		inc di
		loop PRNA1

		add di,140h-4
		mov cx,bx
		dec bx
		loop PRNA2

		pop di
		add di,4
		pop si
		jmp DESPOINTERFOUND
ENDOFDESC_ENTRY: ret

		;------------------------------------
RESETPROG:	mov dx,0
		mov bh,0
		mov ah,2
		int 10h

		mov dx,DATA
		mov ds,dx
		mov dx,offset RESET_TEXT
		mov ah,9
		int 21h

RPLOOP:		call GETAX
		cmp al,"y"
		je RESET_
		cmp al,"n"
		je DOITAGAIN
		jmp RPLOOP


RESET_:		call RESETSEQUENCE
		jmp RESTART


FIRSTENTRY:	mov si,offset SCRIPTPOE
		mov ax,0
		jmp SAMEASBEFORE

LASTENTRY:	mov si,offset SCRIPTPOE
		mov di,offset SCRIPTNOE
		mov ax,[di]
		jmp SAMEASBEFORE

BEFORE:		mov si,offset SCRIPTPOE
		mov ax,[si]
		cmp ax,0
		je MAIN_LOOP
		dec ax
SAMEASBEFORE:	mov [si],ax

		rol ax,2
		add ax,offset SCRIPTDATA
		mov si,ax

		mov al,[si+1]
		mov di,offset LIBPOE
		mov [di],al
		mov al,[si+2]
		mov ah,[si+3]
		mov di,offset ABSXPOS
		mov [di],al
		mov [di+1],ah
		call ADJSCRIPTPOINTER
		jmp DOITAGAIN

AFTER:		mov si,offset SCRIPTPOE
		mov ax,[si]
		mov di,offset SCRIPTNOE
		cmp ax,[di]
		je MAIN_LOOP
		inc ax
		jmp SAMEASBEFORE

		;--------------------------------------------------

SAVESCR:	mov dx,0	; Positionne le curseur
		mov bh,0
		mov ah,2
		int 10h

		mov dx,offset OVERWRITESCRIPT
		call CONVENSIONS
		mov ah,9
		int 21h

SSLOOP:		call GETAX
		call CONVENSIONS
		cmp al,"y"
		je OVERWRITESCR
		cmp al,"n"
		je DOITAGAIN
		jmp SSLOOP

OVERWRITESCR:
		mov si,offset SCR_EXT
		mov di,offset TEMPBUFNAME
		mov bl,[di+1]
		mov bh,0
		add di,bx
		add di,2
		call EXT

		mov dx,offset TEMPBUFNAME+2
		;mov ah,9
		;int 21h
		;jmp QUIT
		call MAKEPATH

		mov dx,offset FILENAME
		mov cx,0
		mov ah,3ch	; CRÉE
		int 21h
		jc UNABLEW

		mov bp,ax
		mov bx,ax

		call CONVENSIONS
		mov si,offset SCRIPTDATA
LOOKFORITAGAIN:	 mov al,[si]
		cmp al,0
		je OKFOUNDENDOFSCR
		add si,4
		loop LOOKFORITAGAIN

OKFOUNDENDOFSCR: sub si,offset SCRIPTDATA
		mov cx,si
		add cx,4
		mov dx,DATA
		mov ds,dx
		mov dx,offset SCRIPTDATA
		mov ah,40h
		int 21h
		jc UNABLEW

		mov bx,bp
		mov ah,3eh
		int 21h
		jc UNABLEW
		jmp DOITAGAIN

		;---------------------------------------------

;WHICHLIB	db "LIBRAIRY OBJ:"
;LIBOBJNUM	db 0,0,0,0
;WHICHSCR	db "SCRIPT ENTRY:"
;SCRNUMBER	db 0,0,0,0

SHOWIDCODE:

		mov si,offset SCRIPTPOE
		mov ax,[si]
		mov di,offset SCRNUMBER
		call DECTOHEXCONV
		mov si,offset LIBPOE
		mov ax,[si]
		mov di,offset LIBOBJNUM
		call DECTOHEXCONV

		mov si,offset WHICHLIB
		mov di,21*0a00h
		call DRAWLINEOFOUTPUT

		mov si,offset WHICHSCR
		mov di,20*0a00h
		call DRAWLINEOFOUTPUT
		ret


		;----------------------------------------------

DECTOHEXCONV:	mov bx,ax
		shr ax,12
		and ax,15
		call WRITEDIGIT
		mov ax,bx
		shr ax,8
		and ax,15
		call WRITEDIGIT
		mov ax,bx
		shr ax,4
		and ax,15
		call WRITEDIGIT
		mov ax,bx
		and ax,15
		call WRITEDIGIT
		ret

WRITEDIGIT:	cmp ax,10
		jb SOMENUM
		sub ax,10
		add ax,"A"
		jmp WRITE_HEY
SOMENUM:	add ax,"0"
WRITE_HEY:	mov [di],al
		inc di
		ret

		;----------------------------------------------
		; DRAWLINEOFOUTPUT
		;
		; INPUTS:
		; DS:[si] : start of chain
		; GS:[di] : destination of draw
		;----------------------------------------------

DRAWLINEOFOUTPUT:
		call CONVENSIONS
		pusha
		mov dx,SCREEN
		mov gs,dx

DLAGAIN:	mov al,[si]
		cmp al,0
		je DRAWLOVER

		push si
		mov si,offset ASCII_TABLE
KEEPSEARCHING:	cmp al,[si]
		je FOUNDMATCH_DL
		inc si
		loop KEEPSEARCHING

FOUNDMATCH_DL:  sub si,offset ASCII_TABLE
		rol si,6
		add si,offset ASCII

		push di

		mov bx,8
DL8V:		mov cx,8/4
DL8H:		mov eax,[si]
		mov gs:[di],eax
		add di,4
		add si,4
		loop DL8H

		add di,140h-8
		mov cx,bx
		dec bx
		loop DL8V

		pop di
		pop si
		add di,8
		inc si
		jmp DLAGAIN

DRAWLOVER:	popa
		ret



		;-------------------------------------------

DECIMA:		mov si,offset LIBPOE
		mov ax,[si]
		cmp ax,0
		je MAIN_LOOP
		dec ax
ADJIMA:		mov [si],ax
		mov cx,ax
		call USECHANGESHAPE
		jmp DOITAGAIN
USECHANGESHAPE:	pusha
		call CONVENSIONS
		jmp CHANGESHAPE

		;////////////////////////////////////////////////////

INCIMA:		mov si,offset LIBPOE
		mov ax,[si]
		mov di,offset LIBNOE
		mov bx,ax
		inc bx
		cmp bx,[di]
		jae MAIN_LOOP
		inc ax
		jmp ADJIMA

		;--------------------------------------------------
OBJUP:		mov si,offset ABSXPOS
		mov al,[si+1]
		cmp al,0
		je IMPO_1
		dec al
COBJUP:		mov [si+1],al
		jmp DOITAGAIN

IMPO_1:		cmp byte ptr MY,0
		je IMPO
                dec byte ptr MY
                jmp DoItAgain

OBJDN:		mov si,offset ABSXPOS
		mov al,[si+1]
		mov di,offset LIBPOINTER
		mov di,[di]
		mov ah,25
		sub ah,fs:[di+4]
		cmp al,ah
		jae IMPO_2
		;cmp al,18
		;jae IMPO
		inc al
		jmp COBJUP

IMPO_2:		inc byte ptr MY
		jmp DoItAgain

OBJLF:		mov si,offset ABSXPOS
		mov al,[si]
		cmp al,0
		je IMPO
		dec al
		mov [si],al
		jmp DOITAGAIN

OBJRG:		mov si,offset ABSXPOS
		mov al,[si]

		call CONVENSIONS
		mov si,offset LIBPOINTER
		mov si,[si]
		mov ah,255
		sub ah,fs:[si+3]		; 255-LENGH
		cmp al,ah
		ja IMPO
		inc al
		mov si,offset ABSXPOS
		mov [si],al
		jmp DOITAGAIN

IMPO:		jmp MAIN_LOOP
		jmp QUIT

		;-------------------------------------------------------

ADDTOSCRIPT:    call CONVENSIONS

		mov di,offset SCRIPTPOINTER
		mov di,[di]

		mov si,offset MX
		mov al,[si]

		mov si,offset SCREENX1
		mov bl,[si]
		mov bh,[si+1]
                add bh,byte ptr MY	; Add-on August 1st 1994

		add bl,al
		;add bh,al

		mov al,1
		mov [di],al

		mov si,offset LIBPOE
		mov al,[si]
		mov [di+1],al
		mov [di+2],bl
		mov [di+3],bh

		;---------------------------------
		mov si,offset SCRIPTPOE
		mov ax,[si]
		mov si,offset SCRIPTNOE
		cmp ax,[si]
		jne SPECIALTOUCH
		;---------------------------------

		mov si,offset SCRIPTNOE
		mov ax,[si]
		inc ax
		mov [si],ax
		mov si,offset SCRIPTPOE
		mov [si],ax
COMMUNTASK:	call SCRIPT_COMPILER
		call ADJSCRIPTPOINTER
		jmp DOITAGAIN
		;jmp ANOTHERSCRIPT

		;---------------------------------------------

SPECIALTOUCH:   mov si,offset SCRIPTPOE
		mov ax,[si]
		;inc ax
		mov [si],ax

		rol ax,2
		add ax,offset SCRIPTDATA
		mov si,ax

		mov al,[si+1]		; OBJ NUM FROM LIB
		mov di,offset LIBPOE
		mov [di],al

		mov di,offset ABSXPOS
		mov al,[si+2]
		mov [di],al
		mov al,[si+3]
		mov [di+1],al
		jmp COMMUNTASK

		;-----------------------------------------------------
		;*****************************************************
		;-----------------------------------------------------

ADJSCRIPTPOINTER:
		pusha

		call CONVENSIONS
		mov si,offset SCRIPTPOE
		mov si,[si]
		rol si,2
		add si,offset SCRIPTDATA
		mov di,offset SCRIPTPOINTER
		mov [di],si

		mov si,offset LIBPOE
		mov cl,[si]
		mov ch,0

CHANGESHAPE:	mov di,offset LIBPOE
		mov [di],cx

		mov si,4
		cmp cx,0
		je OBJFROMLIB0

		;mov si,4
GOREADPTR:	mov si,fs:[si+6]
		loop GOREADPTR

OBJFROMLIB0:	mov di,offset LIBPOINTER
		mov [di],si

		popa
		ret

READSCREENXY:   call CONVENSIONS
		mov si,offset SCRIPTPOINTER
		mov si,[si]
		mov di,offset ABSXPOS

		mov al,[si+2]
		mov [di],al
		mov al,[si+3]
		mov [di+1],al
		ret

		;-----------------------------------------------

ADJSCREENXY_MX:	pusha
		;mov si,offset SCRIPTPOINTER
		;mov si,[si]
		mov si,offset ABSXPOS
		; CORRECTION
		mov al,[si+0]			; R-SCREEN X1
		mov ah,[si+1]                   ; R-SCREEN Y1

		mov bl,0

		;CORRECTION
		cmp al,12
		jb NOMODIFICATIONS
		cmp al,228
		jae MXVAL216

		mov bl,al
		sub bl,12		; MX=SCREEN X1-12
		mov al,12               ; SCREEN X1=12
		jmp NOMODIFICATIONS

MXVAL216:	mov bl,216		; MX=216
		sub al,216              ; SCREEN X1=SCREEN X1-216

NOMODIFICATIONS:mov di,offset SCREENX1
		mov [di],al		; W-SCREEN X1
		mov [di+1],ah           ; W-SCREEN Y1

		mov di,offset MX
		mov [di],bl		; W-MX

		mov si,offset LIBPOINTER
		mov si,[si]
		add al,fs:[si+3]
		sub al,1
		add ah,fs:[si+4]
		sub ah,1

		mov di,offset SCREENX2
		mov [di],al             ; W-SCREEN X2
		mov [di+1],ah           ; W-SCREEB Y2

		popa
		ret

		;----------------------------------------------------

DRAWBORDERS:	pusha
		call CONVENSIONS

		mov si,offset SCREENX1
		mov al,[si+1]
		mov ah,0ah
		mul ah				; AX=AL*AH
		rol ax,8			; AX= Y*0a00h
		mov di,ax

		mov al,[si]
		mov ah,0
		rol ax,3
		add di,ax
		mov bx,di

		mov si,offset COLOR
		mov al,[si]
		inc al
		cmp al,8
		jb COLORNOT8
		mov al,1
COLORNOT8:	mov [si],al

		mov cx,4
PHBORDER:	mov gs:[di],al
		mov gs:[bx],al
		inc di
		add bx,140h
		loop PHBORDER

		push ax

		mov si,offset SCREENX2
		mov al,[si+1]
		mov ah,0ah
		mul ah
		rol ax,8
		mov di,ax

		mov al,[si]
		mov ah,0
		rol ax,3
		add di,ax
		mov bx,di
		add di,7*140h+4
		add bx,7+4*140h

		pop ax

		mov cx,4
PLBORDER:	mov gs:[di],al
		mov gs:[bx],al
		inc di
		add bx,140h
		loop PLBORDER

		popa
		ret

		;---------------------------------------------

DRAWMOVABLEIMAGE:pusha
		call CONVENSIONS

		mov si,offset LIBPOINTER
		mov si,[si]

		mov al,fs:[si+3]	; LENGHT
		mov ah,0
		mov bp,ax		; BP=LENGHT

		mov al,fs:[si+4]	; HEIGHT
		mov dx,ax		; DX= HEIGHT

		mov si,offset SCREENX1
		mov al,[si+1]         	; Y1
		mov ah,0ah
		mul ah                  ; AX=Y1*0ah
		rol ax,8		; AX=Y1*0a00h
		mov di,ax

		mov al,[si]		; X1
		mov ah,0
		rol ax,3		; AX=X1*8
		add di,ax

		mov bx,offset LIBPOINTER
		mov bx,[bx]
		add bx,8

READCOL4:	push di
		mov cx,bp

READCOL3:	mov si,fs:[bx]  	; FONT NUMBER
		rol si,6		; "         " * 64

		push di
		push cx
		push bx

		mov bx,8
READCOL2:       mov cx,8

READCOL:	mov al,es:[si]
		cmp al,0
		je NULCOLORXXX
		mov gs:[di],al

NULCOLORXXX:	inc si
		inc di
		loop READCOL

		mov cx,bx
		dec bx
		add di,140h-8
		loop READCOL2

		pop bx
		pop cx
		pop di

		add bx,2
		add di,8
		loop READCOL3

		pop di
		add di,0a00h
		mov cx,dx
		dec dx
		loop READCOL4

		popa
		ret

		;-----------------------------------------------------

		;-------------------------------------------------------
READERROROCCURED:mov dx,offset READERROROCCURED
		jmp SENDERRORMESSAGE
CREATSCRIPTFAIL:mov dx,offset CREATSCRIPTFAILTEXT
		jmp SENDERRORMESSAGE
UNABLEW:	mov dx,offset OVERWRITESCRIPTFAILTEXT
		jmp SENDERRORMESSAGE

		;-----------------------------------------------

INPUTFILENAME:  call CONVENSIONS
		mov dx,offset TEMPBUFNAME
		mov ah,0ah
		int 21h
		ret


	       ;----------------------------------------------
	       ; CONVENSIONS
	       ; INPUTS:
	       ; no inputs
	       ; OUTPUTS:
	       ; DS:DATA,ES:MEM1,FS:MEM2,GS:a000h
	       ;------------------------------------------------

CONVENSIONS PROC NEAR
		push dx
	       mov dx,DATA
	       mov ds,dx
	       mov dx,FONTS
	       mov es,dx
	       mov dx,LIBRAIRY
	       mov fs,dx
	       mov dx,0a000h
	       mov gs,dx
	       pop dx
	       ret
CONVENSIONS ENDP


	  ;----------------------------------------------------

CLEAR_LOCALS:

		;SCRIPTPOINTER	dw 0
		;SCRIPTNOE 	dw 0
		;SCRIPTPOE	dw 0

		;LIBPOINTER	dw 0
		;LIBNOE		dw 0
		;LIBPOE		dw 0

		call CONVENSIONS
		mov ax,0
		mov di,offset SCRIPTPOINTER
		mov [di],ax
		mov di,offset SCRIPTNOE
		mov [di],ax
		mov di,offset SCRIPTPOE
		mov [di],ax
		mov di,offset LIBPOINTER
		mov [di],ax
		mov di,offset LIBNOE
		mov [di],ax
		mov di,offset LIBPOE
		mov [di],ax
		ret

; -----------------------FIN DU PROGRAMME-----------------------
VLAMITS    ENDP                           ; Fin de la procedure
CODE ENDS                                ; Fin du programme
END     VLAMITS                           ; Point d'entree
;---------------------------------------------------------------
