;----------------------------------------------------------------
;       STATICS OBJECT EDITOR V1.1
;       by Francois Blanchette
;----------------------------------------------------------------

INCLUDE C:\MASM61\LISTING\SSFSMAC.INC

;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------

SMOUSE         MACRO
	       push ax
	       mov ax,1
	       int 33h
	       pop ax
	       ENDM

HMOUSE         MACRO
	       push ax
	       mov ax,2
	       int 33h
	       pop ax
	       ENDM

;----------------------------------------------------------------
DATA      SEGMENT

WRK_GRLD 	db 16384 DUP (0)
IMAGE		db 16386 DUP (0)
COPYRIGHT      db "STATIC OBJECTS EDITOR V1.1: (C) 1994 FRANCOIS BLANCHETTE"
PATH           db 0
FILENAME       db 32 DUP (0)
	       db "is missing from disk!$"
STATICS_MSQ    db "STATICS.MSQ",0
MOUSE_DOWN     db "Warning: missing mouse and/or driver.$"
FILES_DOWN     db "Warning: missing or modified file.$"
PAUSE_TEXT     db "Press [space] to continue playing...    $"
ASCII_TABLE    db " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"
	       db "#$%&*().!,/?:;+-{}[]\|`~<>1234567890",0,-1
QWERTYUI       db "QWERTYUI",0
KEYS	       db "qwertyui",0
IO_ERROR       db "I/O Error occured!",0
HIGHCORNER     db "Please select higher corner",0,0,0,0,0
LOWCORNER      db "Please select low corner...",0
SELECTEDIMAGE  db "M)ove, C)opy, E)rase, S)ave, or I)gnore.",0
SELECTDESTTEXT db "SELECT DESTINATION FOR IMAGE ...........",0
MANUALFILLTEXT db "CLICK MOUSE BUTTON WHERE NEEDED!",0
IERRORTEXT     db "NO IMAGE AVAILABLE IN BUFFER!",0
OTHERTASKSTEXT db "M)ove C)opy S)ave or I)gnore.",0
OLD_VIDEO_MODE db 0

SAVEFONTTEXT   db "Save .FNT file:",0
LOADFONTTEXT   db "Load .FNT file:",0
LOADIMAGETEXT  db "Load .IMA file:",0
SAVEIMAGETEXT  db "Save .IMA file:",0
FNT	       db ".fnt",0
IMA	       db ".ima",0

;ASCII	       db 5831 DUP (0)
ASCII	       db 64*(offset QWERTYUI - offset ASCII_TABLE) DUP (5)

NAME_          db 32 DUP (0)
COLOR	       db 1
CHAR	       db 0
FONT	       db 0
BC	       db 1
CD	       db 1

align 2
HEAD_FONT      db 0,0
LDX	       db 255,255
FULLX	       dw 255,255
LASTX	       dw 255,255
LENGHT	       db 0,0


		db "NOTE: This is a modified version of STATICS, now "
                db "      include FNT flipping & rotations methodes."


align 2
ex_		dw 0
fx_		dw 0
gx_		dw 0
hx_		dw 0
ix_		dw 0
jx_		dw 0
kx_		dw 0
lx_		dw 0

DATA   ENDS
;----------------------------------------------------------------

SeizeCases 	EQU 16*64
UneCase		EQU 64
Grild 		EQU offset WRK_GRLD
ex		EQU word ptr ex_
fx		EQU word ptr fx_
gx		EQU word ptr gx_
hx		EQU word ptr hx_
ix		EQU word ptr ix_
jx		EQU word ptr jx_
kx		EQU word ptr kx_
lx		EQU word ptr lx_

;----------------------------------------------------------------
CODE SEGMENT READONLY PUBLIC 'CODE'
VLAMITS  PROC NEAR
;----------------------------------------------------------------
.386

	       mov ah,0fh
	       int 10h
	       call CONVENSIONS

               set <ds>, DATA
	       mov si,offset OLD_VIDEO_MODE
	       mov [si],al

		; FIXE LE MODE VID…O 13H
REINIT:		mov ah,0
		mov al,13h
		int 10h

               	EmulateStaticsMSQ DATA, offset ASCII, offset ASCII_TABLE

		; CHARGEMENT DE STATICS.MSQ
		;mov dx,DATA
		;mov ds,dx
		;mov es,dx
		;mov dx,offset STATICS_MSQ
		;mov bx,offset ASCII
		;mov cx,5831-7
		;call LOADOLD

		; INITIALISE LE PILOTE DE SOURIS
		mov ax,0
		int 33h


RESTART:	call CONVENSIONS
		mov eax,00060006h
		call MELO_PAINT
		call PRINT_WHITE_LINES
		call PRINT_QWERTYUI
		call DYSPLAY_WORK_GRILD
		call DYSPLAY_FONT_IN_GRILD
		call DYSPLAY_COLORS_PALETTE
		SMOUSE
		mov bp,sp

		; The main loop of the editor is used to be installed
		; and generated. The purpose of this portion of program
		; is to operate the centrals fonctions.

MAIN_LOOP:	call GETAX

		;-----------------------------------------
		; Change color on the "palette".
		cmp al,"["
		je DECPAL
		cmp al,"]"
		je INCPAL
		cmp al," "
		je COLOR_BLACK

		;-----------------------------------------
		;CLEAR EDITING GRILD
		cmp al,"c"
		je CLR_EGRILD
		cmp al,"C"
		je CLR_ALL

		;-----------------------------------------
		;LOAD/SAVE WORK GRILD
		cmp al,"-"
		je LOADFONTS
		cmp al,"="
		je SAVEFONTS

		cmp al,"8"
		je UP_LINK
		cmp al,"2"
		je DOWN_LINK
		cmp al,"4"
		je LEFT_LINK
		cmp al,"6"
		je RIGHT_LINK

		cmp al,"`"
		je REAL_BLACK
		cmp al,"~"
		je INVERSE_GRILD


		;------------------------------------------
		; "qwertyui"
		cmp al,0
		jne SHORTKEYS

		;------------------------------------------
		; ****** SPECIAL FONCTIONS KEYS ******
		;------------------------------------------

		;cmp ah,59
		;je F1_KEY

		;cmp ah,60	; Manual Fill
		;je F2_KEY
		cmp ah,62	; Selection d'une image .IMA
		je F3_KEY
		cmp ah,61	; Chargement d'une image .IMA
		je F4_KEY
		cmp ah,63	; Zoom
		je F5_KEY

                ifedo ah,64, F6_KEY ; rotate
                ifedo ah,65, F7_KEY ; flip LEFT/RIGHT
                ifedo ah,66, F8_KEY ; flip UP/DOWN

		;cmp ah,64       ; Rotate
		;je F6_KEY
		;cmp ah,65	; Flip LEFT/RIGHT
		;je F7_KEY
		;cmp ah,66	; Flip UP/DOWN
		;je F8_KEY

		cmp ah,67       ; Use image stored in buffer
		je F9_KEY	;

		jmp CHK_MOUSE
		;-------------------------------------------------------

		; Use a image stored in the buffer as an active
		; static object. If the buffer is empty or corrupted
		; the program will generate an error,

F9_KEY:         HMOUSE
		mov eax,00060006h
		call MELO_PAINT
		call DYSPLAY_WORK_GRILD

		mov si,offset IMAGE
		mov dx,DATA
		mov fs,dx

		mov al,fs:[si]
		cmp al,0
		je IERROR
		cmp al,16
		jae IERROR

		mov al,fs:[si+1]
		cmp al,0
		je IERROR
		cmp al,16
		je IERROR

		;------------------

		mov al,0
		mov di,offset HEAD_FONT
		mov [di],al

		mov si,offset IMAGE
		mov al,fs:[si]
		mov ah,fs:[si+1]
		dec al
		dec ah
		rol ah,4
		add al,ah
		mov [di+1],al

		mov di,0
		mov si,offset OTHERTASKSTEXT
		call DYSPLAYTEXT40

		;call REDRAW_IMAGE
		call DRAW_IMAGE_ON_GRILD
OTHERTASKS:	call SHOWLIMITS
		call GETAX
		cmp al,"e"
		je ERASE_ONLY
		cmp al,"i"
		je RESTART
		cmp al,"m"
		je IMOVE_TASK
		cmp al,"c"
		je MOVE_TASK
		cmp al,"s"
		je SAVEIMAGE

		cmp al,9
		je RESTART
		jmp OTHERTASKS

IMOVE_TASK:	mov al,"c"
		jmp MOVE_TASK

IERROR:		mov si,offset IERRORTEXT
		mov di,0
		call DYSPLAYTEXT40

IERROR_:	call GETAX
		cmp al,0
		je IERROR_
		jmp RESTART







		;-----------------------------------------------------
F5_KEY:         ; This is the magic zoom. Created to make the hold
		; editing grild look green. It should eventualy work
		; and will allow me a greater flexibility in drawing
		; images.
		;-----------------------------------------------------

		mov dx,DATA
		mov fs,dx

		mov ax,255
		mov si,offset LASTX
		mov [si],ax
		mov [si+2],ax
		mov si,offset LDX
		mov [si],al
		mov [si+1],al

		mov si,offset FONT
		mov al,[si]
		and al,15
		cmp al,15-4
		jbe NOADJX
		mov al,11

NOADJX:		mov ah,[si]
		shr ah,4
		and ah,15
		cmp ah,15-4
		jbe NOADJY
		mov ah,11

NOADJY:		rol ah,4
		add al,ah
		mov [si],al

		HMOUSE

		mov eax,00060006h
		call MELO_PAINT

		call QWERTYUI_2
		call COLOR_PALLET2
		call SMALL_WORK_GRILD

		call DYSPLAY_ZOOMED_GRILD

		SMOUSE

ZOOMYLOOP:	call GETAX

		mov si,offset FONT
		mov bl,[si]
		mov bh,[si]

		cmp al,"8"
		je ZUP
		cmp al,"2"
		je ZDN
		cmp al,"4"
		je ZLF
		cmp al,"6"
		je ZRG

		cmp al,"["
		je DECPAL_
		cmp al,"]"
		je INCPAL_

		cmp al," "
		je BLACKCOLOR

		cmp al,9
		je RESTARTH
		cmp ah,63
		je RESTARTH

		cmp al,0
		jne MANUALKEYS

		mov ax,3
		int 33h

		cmp bx,0
		je ZOOMYLOOP

		shr cx,1
		mov si,offset FULLX
		mov [si],cx
		mov [si+2],dx

		shr cx,3
		shr dx,3

		cmp cx,4*8
		jae XZOOMGRLD
		cmp dx,3*8
		jae XZOOMGRLD

		mov si,offset LDX

		cmp cl,[si]
		jne OKMAYDO
		cmp dl,[si+1]
		jne OKMAYDO
		jmp ZOOMYLOOP

OKMAYDO:	mov [si],cl
		mov [si+1],dl

		mov ch,cl
		mov dh,dl

		; DI = FONT*64 + (CL AND 7) + (CH/8)*64 +
		;	(DL AND 7)*8 + (DH/8)*64*16


		and cl,7		; CL AND 7
		and dl,7		; DL AND 7
		shr ch,3		; CL/8
		shr dh,3		; DL/8

		mov si,offset FONT
		mov al,[si]
		mov ah,0
		rol ax,6		; FONT*64
		mov di,ax		; DI=FONT*64

		mov ax,cx
		mov ah,0
		add di,ax		; DI=DI+(CL AND 7)

		mov al,ch
		mov ah,0
		;shr ax,3
		rol ax,6
		add di,ax		; DI=DI+(CH/8)*64

		mov al,dl
		mov ah,0
		;and al,7
		rol ax,3
		add di,ax		; DI=DI+(DL AND 7)*8

		mov al,dh
		mov ah,0
		;shr ax,3
		rol ax,10
		add di,ax		; DI=DI+(DH/8)*16*64

		mov si,offset CD
		mov al,[si]
		mov fs:[di],al

		mov si,offset LDX
		mov al,[si]
		mov ah,0
		rol ax,3
		mov di,ax		; DI=X*8

		mov al,[si+1]
		mov ah,0ah
		mul ah
		mov ah,0
		rol ax,8
		add di,ax		; DI=X*8+Y*0a00h

		mov si,offset CD
		mov al,[si]

		HMOUSE

		mov bx,8
SGRLD2:		mov cx,8

SGRLD1:		mov gs:[di],al
		inc di
		loop SGRLD1

		add di,140h-8
		mov cx,bx
		dec bx
		loop SGRLD2

		call SMALL_WORK_GRILD
		;call DYSPLAY_ZOOMED_GRILD
		SMOUSE
		jmp ZOOMYLOOP




XZOOMGRLD:      cmp cl,40-8
		jb NOTPAL
		;cmp cl,39
		;je NOTPAL
		cmp dl,10
		jne NOTPAL

		sub cl,40-8
		mov si,offset BC
		mov al,[si]
		add al,cl
		mov si,offset CD
		mov [si],al
		jmp ZOOMYLOOP

NOTPAL:		jmp ZOOMYLOOP

		jmp ZOOMYLOOP
		;-----------------------------------------------------

BLACKCOLOR:    	mov si,offset CD
		mov al,0
		mov [si],al
		jmp ZOOMYLOOP

		;-----------------------------------------------------

MANUALKEYS:     mov cx,8
		mov si,offset KEYS
TRYAGAINXXX:	cmp al,[si]
		je KEYMATCHFOUND
		inc si
		loop TRYAGAINXXX
		jmp ZOOMYLOOP

KEYMATCHFOUND:	sub si,offset KEYS
		mov ax,si
		mov si,offset BC
		add al,[si]
		mov si,offset CD
		mov [si],al
		mov al,255
		mov si,offset LDX
		mov [si],al
		jmp ZOOMYLOOP

		;-----------------------------------------------------
		; INCPAL_/DECPAL_:
		;-----------------------------------------------------

INCPAL_:	mov si,offset BC
		mov al,[si]
		cmp al,1-8
		je ZOOMYLOOP
		add al,8
PAL:		mov [si],al

		mov si,offset LDX
		mov al,255
		mov [si],al

		HMOUSE
		call COLOR_PALLET2
		SMOUSE
		jmp ZOOMYLOOP

DECPAL_:	mov si,offset BC
		mov al,[si]
		cmp al,1
		je ZOOMYLOOP
		sub al,8
		jmp PAL

		;------------------------------------------------------
		; This will allow user to asjust the head font
		; for the maximum zoom fonction.
		;------------------------------------------------------

ZUP:		shr bl,4
		cmp bl,0
		je ZOOMYLOOP
		sub bh,16
ADJZ:		mov [si],bh
		HMOUSE
		call SMALL_WORK_GRILD
		call DYSPLAY_ZOOMED_GRILD
		SMOUSE
		jmp ZOOMYLOOP

ZDN:		shr bl,4
		cmp bl,15-3
		ja ZOOMYLOOP
		add bh,16
		jmp ADJZ

ZLF:		and bl,15
		cmp bl,0
		je ZOOMYLOOP
		dec bh
		jmp ADJZ

ZRG:		and bl,15
		cmp bl,15-4
		ja ZOOMYLOOP
		inc bh
		jmp ADJZ

		;-------------------------------------------------------
		; The zoomed grild is only one of the many features that
		; will be adding to the new fully equiped editor. I do
		; hope that it will service me well because if not, I'm
		; going to throw it appart.
		;-------------------------------------------------------

DYSPLAY_ZOOMED_GRILD:

		pusha

		mov si,offset FONT
		mov al,[si]
		mov ah,0
		rol ax,6		; FONT*64

		mov si,ax
		mov di,0

		mov bx,3
DZA6:		push bx
		push di
		push si
		mov cx,4

DZA5:		push cx
		push di

		mov bx,8
DZA4:		mov cx,8
		push bx
		push di

DZA3:		push cx
		mov al,fs:[si]
		inc si
		push di

		mov bx,8
DZA2:		mov cx,8
DZA1:		mov gs:[di],al
		inc di
		loop DZA1
		add di,140h-8
		mov cx,bx
		dec bx
		loop DZA2

		pop di
		pop cx
		add di,8
		loop DZA3

		pop di
		pop bx
		add di,0a00h
		mov cx,bx
		dec bx
		loop DZA4

		pop di
		add di,64
		pop cx
		loop DZA5

		pop si
		pop di
		pop bx
		add si,16*64
		add di,0a00h*8
		mov cx,bx
		dec bx
		loop DZA6

		popa
		ret

		;--------------------------------

SMALL_WORK_GRILD: pusha

		mov si,offset FONT
		mov al,[si]
		mov ah,0
		rol ax,6
		mov si,ax
		mov di,140h-(7*8)+0a00h

		mov dx,3
SWG4:		mov bx,4
		push di
		push si

SWG3:		push bx
		push di

		mov bx,8
SWG2:		mov cx,8

SWG1:		mov al,fs:[si]
		mov gs:[di],al
		inc si
		inc di
		loop SWG1

		add di,140h-8
		mov cx,bx
		dec bx
		loop SWG2

		pop di
		pop bx
		add di,8
		mov cx,bx
		dec bx
		loop SWG3

		pop si
		pop di
		add di,0a00h
		add si,16*64
		mov cx,dx
		dec dx
		loop SWG4

		popa
		ret

QWERTYUI_2:	mov si,offset QWERTYUI
		mov di,0a00h+140h-64+(10*0a00h)
		jmp DYSPLAYTEXT40

		;--------------------------------

COLOR_PALLET2:	mov si,offset BC
		mov al,[si]

		mov di,140h-64+(10*0a00h)
		mov dx,8

CPA3:		push di
		mov bx,8
CPA2:		mov cx,8
CPA1:		mov gs:[di],al
		inc di
		loop CPA1

		add di,140h-8
		mov cx,bx
		dec bx
		loop CPA2

		inc al
		pop di
		add di,8
		mov cx,dx
		dec dx
		loop CPA3
		ret

		;-------------------------------------------------------

F2_KEY:		HMOUSE
		mov eax,00060006h
		call MELO_PAINT
		call DYSPLAY_WORK_GRILD
		mov si,offset MANUALFILLTEXT
		mov di,0
		call DYSPLAYTEXT40

		mov ax,255
		mov si,offset LDX
		mov [si],al
		mov [si+1],al
		mov si,offset LASTX
		mov [si],ax
		mov [si+2],ax


		SMOUSE
FILL_LOOP:	call GETAX
		cmp al,9
		je RESTARTH
		cmp al,13
		je RESTARTH
		cmp ah,0
		jne RESTARTH

		mov ax,3
		int 33h

		cmp bx,0
		je FILL_LOOP

		mov si,offset LASTX
		shr cx,1		; CX=CX/2^1

		cmp cx,[si]
		jne LASTNOMATCH
		cmp dx,[si+2]
		jne LASTNOMATCH
		jmp FILL_LOOP

LASTNOMATCH:	mov [si],cx
		mov [si+2],dx

		shr cx,3
		shr dx,3

		cmp dx,1	; Y<1 then not in grild
		jb FILL_LOOP
		cmp dx,16   	; Y>16 then not in grild
		ja FILL_LOOP
		cmp cx,40-17	; X<40-17 then not in grild
		jb FILL_LOOP
		cmp cx,39       ; X>=39 then not in grild
		jae FILL_LOOP

		; FONT= CX -(40-17) + (DX -1)*16
		sub cx,40-17    ; CX= CX-(40-17)
		sub dx,1
		rol dx,4     	; DX= (DX-1)*16

		mov di,cx
		add di,dx
		rol di,6	; DI= FONT*64

		mov cx,[si]
		mov dx,[si+2]

		and cx,7
		and dx,7
		rol dx,3	; DX= Y*8
		add di,dx	; DI= FONT*64+Y*8
		mov bx,cx       ; BX= offset FROM LINE

		mov dx,DATA
		mov fs,dx

		mov si,offset CD
		mov dl,fs:[di+BX]; DL=pv
		mov dh,[si]	; DH=cd

CHKPV:		cmp bx,0
		je SOFTLINE
		cmp fs:[di+bx],dl
		jne SOFTLINE2
		dec bx
		jmp CHKPV

SOFTLINE2:	inc bx
SOFTLINE:	cmp fs:[di+bx],dl
		jne ENDFILLING
		mov fs:[di+bx],dh
		cmp bx,7
		je ENDFILLING
		jmp SOFTLINE2

ENDFILLING:	HMOUSE
		call DYSPLAY_WORK_GRILD
		SMOUSE

		jmp FILL_LOOP

RESTARTH:	HMOUSE
		jmp RESTART

		;-------------------------------------------------------

REAL_BLACK:	mov al,19
		mov si,offset CD
		mov [si],al
		mov si,offset LDX
		mov al,255
		mov [si],al
		jmp MAIN_LOOP

		;--------------------------------------------------------

INVERSE_GRILD:	mov cx,16384/4
		mov si,0
		mov dx,DATA
		mov fs,dx

INVGRLD:	mov eax,fs:[si]
		xor eax,0f0f0f0f0h
		mov fs:[si],eax
		add si,4
		loop INVGRLD
		HMOUSE
		call DYSPLAY_WORK_GRILD
		SMOUSE
		jmp MAIN_LOOP

		;--------------------------------------------------------
		; AUTO LINKING WITH KEYBOARD SHORT CUTS

UP_LINK:	mov si,offset FONT
		mov al,[si]
		shr al,4
		cmp al,0
		je MAIN_LOOP

		mov al,[si]
		sub al,16
ADJ_LINK:	mov [si],al

		mov si,offset LDX
		mov al,255
		mov [si],al
		mov [si+1],al

		HMOUSE
		call DYSPLAY_FONT_IN_GRILD
		SMOUSE
		jmp MAIN_LOOP

DOWN_LINK:	mov si,offset FONT
		mov al,[si]
		shr al,4
		cmp al,15
		je MAIN_LOOP

		mov al,[si]
		add al,16
		jmp ADJ_LINK

LEFT_LINK:	mov si,offset FONT
		mov al,[si]
		and al,15
		cmp al,0
		je MAIN_LOOP

		mov al,[si]
		dec al
		jmp ADJ_LINK

RIGHT_LINK:	mov si,offset FONT
		mov al,[si]
		and al,15
		cmp al,15
		je MAIN_LOOP

		mov al,[si]
		inc al
		jmp ADJ_LINK

		; This part of the program will gestion the selection
		; of a .IMA image. It will them prompt you to take a
		; choice.

F3_KEY:         HMOUSE

		mov eax,00060006h
		call MELO_PAINT
		call DYSPLAY_WORK_GRILD

		mov di,0
		mov si,offset HIGHCORNER
LOOPA:		mov al,[si]
		cmp al,0
		je XPRINT1
		call PRINT_ONE
		add di,8
		inc si
		loop LOOPA

XPRINT1:        ;mov si,offset HEAD_FONT
		;mov al,0
		;mov [si],al

		call DYSPLAY_WORK_GRILD

UPPERCORNER2:	call SHOWUPPER
		mov si,offset HEAD_FONT
		call CURSOR_CTRL
		cmp al,9
		je RESTART
		cmp al,13
		je LOWERCORNER
		jmp UPPERCORNER2

LOWERCORNER:    mov di,0
		mov si,offset LOWCORNER
LOOPA2:		mov al,[si]
		cmp al,0
		je XPRINT2
		call PRINT_ONE
		add di,8
		inc si
		loop LOOPA2

XPRINT2:	mov si,offset HEAD_FONT
		mov al,[si]
		mov [si+1],al

LOWERCORNER2:	call SHOWLOWER
		call SHOWUPPER
		mov si,offset HEAD_FONT+1
		call CURSOR_CTRL
		cmp al,9
		je RESTART
		cmp al,13
		je SEEKSIZE
		jmp LOWERCORNER2

SEEKSIZE:	mov si,offset HEAD_FONT
		mov di,offset LENGHT

		mov al,[si]
		mov ah,[si+1]
		push ax
		and al,15
		and ah,15
		sub ah,al	; LARGEUR
		inc ah
		mov [di],ah
		pop ax

		shr al,4
		shr ah,4
		sub ah,al       ; HAUTEUR
		inc ah
		mov [di+1],ah

		mov dx,DATA
		mov fs,dx

		; AJUST THIS TEMPORATE MODIFICATION LATER
		mov di,offset IMAGE+2
		;mov di,0

		mov si,offset HEAD_FONT
		mov al,[si]
		and al,15
		mov ah,0
		rol ax,6	; X*64

		mov bl,[si]
		shr bl,4
		mov bh,0
		rol bx,10	; Y*64*16

		mov si,ax
		add si,bx

		push si
		mov si,offset LENGHT
		mov bl,[si]
		mov bh,0
		mov dl,[si+1]
		mov dh,0
		pop si

		;--------------------------------------------------
		; This will transfer the image from the work grild
		; to a temporate buffer for futher uses. This is an
		; essential task for the program.
		;----------------------------------------------------

		push si

XXS3:		push si
		push bx

XXS2:		mov cx,64
XXS:		mov al,fs:[si]
		mov fs:[di],al
		inc si
		inc di
		loop XXS

		mov cx,bx
		dec bx
		loop XXS2

		pop bx
		pop si
		add si,16*64
		mov cx,dx
		dec dx
		loop XXS3

		;--------------------------------------------------
		; Give the new options to the user. They are about
		; what to do with the image. This task is essential.
		; M)ove , C)opy , E)rase , S)ave or I)gnore.
		;---------------------------------------------------

		mov di,0
		mov si,offset SELECTEDIMAGE
CONTTX:		mov al,[si]
		cmp al,0
		je ENDOFTEXTX
		call PRINT_ONE
		add di,8
		inc si
		jmp CONTTX

SHOWLIMITS:     pusha
		call SHOWLOWER
		call SHOWUPPER
		popa
		ret

ENDOFTEXTX:     pop dx
LOOPFORC:	call SHOWLIMITS
		call GETAX
		cmp al,"e"
		je ERASE_ONLY
		cmp al,"i"
		je RESTART
		cmp al,"m"
		je MOVE_TASK
		cmp al,"c"
		je MOVE_TASK
		cmp al,"s"
		je SAVEIMAGE

		cmp al,9
		je RESTART
		jmp LOOPFORC

		;------------------------------------------------------
		; Another important fonction is the ability to save an
		; image to disk for further uses. This news task is
		; made a reality by the next routine.
		;------------------------------------------------------

SAVEIMAGE:      ;HMOUSE
		mov eax,0
		mov cx,0a00h/4
		mov di,0
SVIMTXT:	mov gs:[di],eax
		add di,4
		loop SVIMTXT

		mov si,offset SAVEIMAGETEXT
		mov di,0
		call PRINT_SMALL
		call LOADORSAVE

		cmp si,offset NAME_
		je RESTART

		mov di,offset IMA
		call EXT

		mov dx,offset NAME_
		call MAKEPATH

		mov ah,3ch	; CR…E UN FICHIER
		mov dx,offset FILENAME
		mov cx,0
		int 21h
		jc RESTART2

		push ax
		mov bx,ax

		;--------------------------------
		mov dx,DATA
		mov ds,dx
		mov dx,DATA
		mov fs,dx

		mov si,offset LENGHT
		mov di,offset IMAGE

		mov al,[si]
		mov fs:[di],al
		mov ah,[si+1]
		mov fs:[di+1],ah

		mul ah		; AX=LENGHT*HEIGHT
		rol ax,6        ; AX=LENGHT*HEIGHT*64
		mov cx,ax
		add cx,2

		;--------------------------------

		mov dx,DATA
		mov ds,dx
		mov dx,offset IMAGE

		mov ah,40h	; …CRITURE
		int 21h
		jc RESTART2

		pop bx
		mov ah,3eh
		int 21h
		jc RESTART2

		mov dx,DATA
		mov ds,dx
		jmp RESTART

		SMOUSE
		jmp MAIN_LOOP

		;------------------------------------------------------
		; F4: *** LOAD AN IMAGE FROM DISK ****
		;------------------------------------------------------

F4_KEY:         HMOUSE
		mov eax,00060006h
		call MELO_PAINT

		mov dx,DATA
		mov ds,dx

		mov si,offset LOADIMAGETEXT
		mov di,0
		call PRINT_SMALL
		call LOADORSAVE

		cmp si,offset NAME_
		je RESTART

		mov di,offset IMA
		call EXT

		;mov dx,offset NAME_
		;call MAKEPATH
		;jmp NOT_FOUND

		mov dx,DATA
		mov ds,dx

		mov dx,DATA
		mov es,dx

		mov dx,offset NAME_
		mov bx,offset IMAGE

		mov cx,16*1024+2
		call LOADNEW2

		mov dx,DATA
		mov ds,dx
		mov dx,DATA
		mov fs,dx
		mov dx,0a000h
		mov gs,dx

		mov si,offset HEAD_FONT
		mov al,0
		mov [si],al

		mov si,offset IMAGE
		mov di,offset LENGHT


		; ******* CORRECTION *********
		mov al,fs:[si]
		cmp al,0
		je RESTART2
		cmp al,15+1
		ja RESTART2
		mov [di],al

		mov al,fs:[si+1]
		cmp al,0
		je RESTART2
		cmp al,15+1
		ja RESTART2
		mov [di+1],al

		;mov eax,00060006h
		;call MELO_PAINT

		mov al,255
		jmp MOVE_TASK

ERRORS:
		;---------------------------------------------------

ERASE_ONLY:	call ERASE_IMAGE
		jmp RESTART

		; This part under here is purpose to move an image
		; from one point to another on the work grild. I am
		; not in a hurry to make this one.

MOVE_TASK:      cmp al,"m"
		jne NOERASE_IMAGE
		call ERASE_IMAGE
NOERASE_IMAGE:	mov si,offset LENGHT
		mov bl,[si]		; BL= LENGHT
		dec bl
		mov bh,[si+1]           ; BH= HEIGHT
		dec bh
		rol bh,4		; BH= HEIGHT*16

		mov si,offset HEAD_FONT
		mov al,[si]
		add al,bl
		add al,bh
		mov [si+1],al

		call MOVE_IMAGE
		jmp RESTART

		; --------------------------------------------------
		; MOVE_IMAGE:
		; This is a routine allowing a image to be moved on
		; the editing grild.
		;---------------------------------------------------

MOVE_IMAGE:     mov di,0
		mov si,offset SELECTDESTTEXT
		call DYSPLAYTEXT40
UPDATEMOVE:	call DYSPLAY_WORK_GRILD
		call DRAW_IMAGE_ON_GRILD

AWAYSTHNG:	call SHOWLIMITS
		call GETAX
		cmp al,9
		je RDOUT

		mov si,offset HEAD_FONT
		mov bl,[si]
		mov bh,[si+1]
		mov cx,bx

		cmp al,13
		je REDRAWAPP
		cmp al,"8"
		je MOVEUP
		cmp al,"2"
		je MOVEDN
		cmp al,"4"
		je MOVELF
		cmp al,"6"
		je MOVERG
		jmp AWAYSTHNG

REDRAWAPP:	call REDRAW_IMAGE
RDOUT:		ret

MOVEUP:         shr cl,4
		cmp cl,0
		je AWAYSTHNG
		sub bl,16
		sub bh,16
ADJMOV:		mov [si],bl
		mov [si+1],bh
		jmp UPDATEMOVE

MOVEDN:		shr ch,4
		cmp ch,15
		je AWAYSTHNG
		add bl,16
		add bh,16
		jmp ADJMOV

MOVELF:		and cl,15
		cmp cl,0
		je AWAYSTHNG
		dec bl
		dec bh
		jmp ADJMOV

MOVERG:		and ch,15
		cmp ch,15
		je AWAYSTHNG
		inc bl
		inc bh
		jmp ADJMOV

		;-----------------------------------------------------
		; REDRAW_IMAGE:
		; Draws the image stored in the temporate buffer
		; back into the work grild. This process is routine
		; like.
		;-----------------------------------------------------

REDRAW_IMAGE:   pusha

		mov dx,DATA
		mov fs,dx

		mov si,offset HEAD_FONT
		mov al,[si]
		mov ah,0
		rol ax,6		; AX=FONT*64
		mov di,ax

		mov si,offset LENGHT
		mov bl,[si]
		mov bh,0
		mov dl,[si+1]
		mov dh,0
		mov si,offset IMAGE+2

		push bp
		mov bp,bx

IMA3R:		push di
IMA2R:		mov cx,64
IMA1R:		mov al,fs:[si]
		cmp al,0
		je NOREDRAWNUL
		mov fs:[di],al
NOREDRAWNUL:	inc si
		inc di
		loop IMA1R

		mov cx,bx
		dec bx
		loop IMA2R

		pop di
		mov bx,bp
		add di,16*64
		mov cx,dx
		dec dx
		loop IMA3R

		pop bp
		popa
		ret

		;---------------------------------------------------
		; The part of the program overlay a image on to the work
		; grild to make it looking like a part of the grild.
		; In fact, this methode should work in the near future
		; correctly so I could take advantage of it.
		;------------------------------------------------------

DRAW_IMAGE_ON_GRILD:pusha
		mov dx,DATA
		mov fs,dx

		mov si,offset HEAD_FONT
		mov al,[si]
		mov bl,[si]

		and ax,15	; AX=X
		mov bh,0
		shr bl,4	; BX=Y

		rol ax,3	; AX=X*8
		push ax

		mov al,bl
		mov bl,0ah
		mul bl		; AX=AL*BL (Y*0ah)
		rol ax,8	; AX=Y*0A00H

		mov di,ax
		pop ax
		add di,ax
		add di,0a00h+(40-17)*8

		; The transfer will be done by the part below this
		; point. I will have to check it again. I'm sure to
		; find bug in the structure.

		mov si,offset LENGHT
		mov bl,[si]
		mov bh,0
		mov dl,[si+1]
		mov dh,0

		push bp
		mov bp,bx

		mov si,offset IMAGE+2
DIMA4:		push di
DIMA3:  	push bx
		push di

		mov bx,8
DIMA2:		mov cx,8

DIMA1:		mov al,fs:[si]
		cmp al,0
		je NULBYTEZZZ
		mov gs:[di],al
NULBYTEZZZ:	inc si
		inc di
		loop DIMA1

		add di,140h-8
		mov cx,bx
		dec bx
		loop DIMA2

		pop di
		pop bx
		add di,8
		mov cx,bx
		dec bx
		loop DIMA3

		pop di
		mov bx,bp
		add di,0a00h
		mov cx,dx
		dec dx
		loop DIMA4

		pop bp
		popa
		ret


	       ;----------------------------------------------------
	       ; Dysplay a 40-colums text for SI

DYSPLAYTEXT40:	mov al,[si]
		cmp al,0
		je DYSPT40OUT
		call PRINT_ONE
		inc si
		add di,8
		jmp DYSPLAYTEXT40
DYSPT40OUT:	ret

		;--------------------------------------------------
		; This is purpose to erase the image from the grild

ERASE_IMAGE:    pusha
		mov di,dx
		mov dx,DATA
		mov fs,dx
		mov si,offset LENGHT
		mov bl,[si]
		mov dl,[si+1]
		mov bh,0
		mov dh,0

ERIMA3:		push di
		push bx

ERIMA2:		mov cx,64
		mov al,0
ERIMA1:		mov fs:[di],al
		inc di
		loop ERIMA1

		mov cx,bx
		dec bx
		loop ERIMA2

		pop bx
		pop di
		add di,16*64
		mov cx,dx
		dec dx
		loop ERIMA3

		popa
		ret

		;----------------------------------------------------

SHOWUPPER:	mov si,offset HEAD_FONT
		mov al,[si]
		shr al,4
		and al,15
		inc al
		mov bl,0ah
		mov ah,0
		mul bl
		mov bh,0
		rol ax,8		; AX=Y*0a00h

		mov bl,[si]		; BX=X*8
		and bx,15
		rol bx,3

		mov di,ax
		add di,bx
		add di,(40-17)*8
		mov bx,di

		mov si,offset COLOR
		mov al,[si]

		mov cx,4
ENDON:		mov gs:[di],al
		mov gs:[bx],al
		inc di
		add bx,140h
		loop ENDON

		inc al
		cmp al,8
		jbe XADF
		mov al,1
XADF:		mov [si],al
		ret

		;----------------------

SHOWLOWER:	mov si,offset HEAD_FONT+1
		mov al,[si]
		shr al,4
		and al,15
		inc al
		mov bl,0ah
		mov ah,0
		mul bl
		mov bh,0
		rol ax,8		; AX=Y*0a00h

		mov bl,[si]		; BX=X*8
		and bx,15
		rol bx,3

		mov di,ax
		add di,bx
		add di,(40-17)*8
		mov bx,di

		add bx,140h*4+7
		add di,140h*7+4

		mov si,offset COLOR
		mov al,[si]

		mov cx,4
ENDON2:		mov gs:[di],al
		mov gs:[bx],al
		inc di
		add bx,140h
		loop ENDON2
		ret


		;----------------------

CURSOR_CTRL:	call GETAX

		mov di,offset HEAD_FONT
		mov cl,[di]
		and cl,15
		mov ch,[di]
		shr ch,4
		mov bl,[si]

		cmp al,"8"
		je UP_C
		cmp al,"2"
		je DOWN_C
		cmp al,"4"
		je LEFT_C
		cmp al,"6"
		je RIGHT_C
OOOH:		ret

		;------------------------

UP_C:           shr bl,4
		cmp di,si
		je UPC1

		cmp bl,ch
		je OOOH
UPC1:		cmp bl,0
		je OOOH

		mov bl,[si]
		sub bl,16
ADJ_UPC:	mov [si],bl
		call DYSPLAY_WORK_GRILD
		ret

		;-------------------
DOWN_C:		shr bl,4
		cmp bl,15
		je OOOH

		mov bl,[si]
		add bl,16
		jmp ADJ_UPC

		;---------------------------

LEFT_C:		and bl,15

		cmp si,di
		je LEFTC1
		cmp bl,cl
		je OOOH
LEFTC1:		cmp bl,0
		je OOOH

		mov bl,[si]
		dec bl
		jmp ADJ_UPC

		;--------------------------

RIGHT_C:	and bl,15
		cmp bl,15
		je OOOH

		mov bl,[si]
		inc bl
		jmp ADJ_UPC

		;----------------------------

		SMOUSE
		jmp MAIN_LOOP
		jmp MAIN_LOOP


		;****************************************************
		;----------------------------------------------------
		; LOAD/SAVE FONTS (WORK GRILD)
		;----------------------------------------------------

SAVEFONTS:      HMOUSE
		mov eax,0
		call MELO_PAINT

		mov si,offset SAVEFONTTEXT
		mov di,0
		call PRINT_SMALL
		call LOADORSAVE

		;SMOUSE

		cmp si,offset NAME_
		je RESTART

		mov di,offset FNT
		call EXT

		mov dx,offset NAME_
		call MAKEPATH

		mov ah,3ch	; CR…E UN FICHIER
		mov dx,offset FILENAME
		mov cx,0
		int 21h
		jc RESTART2

		push ax
		mov bx,ax
		mov dx,DATA
		mov ds,dx
		mov dx,0
		mov ah,40h	; …CRITURE
		mov cx,16384
		int 21h
		jc RESTART2

		pop bx
		mov ah,3eh
		int 21h
		jc RESTART2

		mov dx,DATA
		mov ds,dx
		jmp RESTART

		SMOUSE
		jmp MAIN_LOOP

		;**************************************************

LOADFONTS:      HMOUSE
		mov eax,0
		call MELO_PAINT

		mov si,offset LOADFONTTEXT
		mov di,0
		call PRINT_SMALL
		call LOADORSAVE

		cmp si,offset NAME_
		je RESTART
		mov di,offset FNT
		call EXT

		mov dx,DATA
		mov ds,dx
		mov dx,DATA
		mov es,dx
		mov dx,offset NAME_
		mov bx,0
		mov cx,16384
		call LOADNEW2
		jmp RESTART

		;--------------------------------------------
		; EXT:
		; INPUTS:
		; [SI] offset of name
		; [DI] offset of EXTENSION
		; OUTPUTS:
		; add extension to name
		;-----------------------------------------------

EXT:		pusha
		mov cx,5
MRE:		mov al,[di]
		mov [si],al
		inc si
		inc di
		loop MRE
		popa
		ret


		;---------------------------------------------

LOADORSAVE:     mov di,offset NAME_
		mov al,0
		mov cx,16
CLRNAMEBUF:	mov [di],al
		inc di
		loop CLRNAMEBUF

		mov si,offset NAME_
		mov di,((offset LOADFONTTEXT-SAVEFONTTEXT)*4)-4

AAAAH:		push di
		push si

		mov cx,8
		;modifications
		mov eax,0e0e0e0eh
DRWCURS:	mov gs:[di],eax
		add di,140h
		loop DRWCURS

		pop si
		pop di
		push ax
CHKEYSB:        pop ax
		call GETAX
		push ax
		call EEESCANKEY
		jc CHKEYSB
		pop ax
		cmp al,13
		je OUTX
XAD:		jmp AAAAH
OUTX:		ret

		;---------------------------------------------

EEESCANKEY:	cmp al,"a"
		jb CALPHA2
		cmp al,"z"
		ja CALPHA2
		jmp AKEY

CALPHA2:	cmp al,"A"
		jb CNUM
		cmp al,"Z"
		ja CNUM
		jmp AKEY

CNUM:		cmp al,"0"
		jb SCHAR
		cmp al,"9"
		ja SCHAR
		jmp AKEY

SCHAR:		cmp al,"!"
		je AKEY
		cmp al,"#"
		je AKEY
		cmp al,"$"
		je AKEY
		cmp al,"&"
		je AKEY
		cmp al,"("
		je AKEY
		cmp al,")"
		je AKEY

                ; Modification 11/12/94
                ifedo al,".",AKey
                ifedo al,"\",AKey

		cmp al,8
		je BACKSPACE
		cmp al,13
		je POUTS
		stc
		ret

AKEY:           push di
		push si

		mov dx,ax

		mov si,offset ASCII_TABLE
CAKEY:		cmp al,[si]
		je AKEYMT
		inc si
		jmp CAKEY

AKEYMT:		sub si,offset ASCII_TABLE
		rol si,6
		add si,offset ASCII

		mov bx,8
CAKEY2:		mov cx,4
CAKEY1:		mov al,[si]
		mov gs:[di],al
		inc si
		inc si
		inc di
		loop CAKEY1

		add di,140h-4
		mov cx,bx
		dec bx
		loop CAKEY2

		pop si
		pop di

		mov [si],dl
		add di,4
		inc si
POUTS:		clc
		ret
OUTT:		stc
		ret

BACKSPACE:      stc
		cmp si,offset NAME_
		je OUTT

		dec si
		push di

		mov cx,8
		;mov eax,00060006h
		mov eax,0
XBS:		mov gs:[di],eax
		add di,140h
		loop XBS

		pop di
		sub di,4
		clc
		ret

		;---------------------------------------------------

CLR_ALL:	mov di,0
		mov dx,DATA
		mov fs,dx
		mov eax,0
		mov cx,16384/4
CLA:		mov fs:[di],eax
		add di,4
		loop CLA
		jmp COM

		; CLEAR EDITING GRILD
CLR_EGRILD: 	mov si,offset FONT
		mov al,[si]
		mov ah,0
		rol ax,6
		mov di,ax

		mov dx,DATA
		mov fs,dx

		mov eax,0
		mov cx,8*8/4
CLE:		mov fs:[di],eax
		add di,4
		loop CLE

COM:		HMOUSE

		call DYSPLAY_FONT_IN_GRILD
		call DYSPLAY_WORK_GRILD

		mov si,offset LDX
		mov al,255
		mov [si],al
		mov [si+1],al

		SMOUSE

		;---------------------------------------------
		; VÈfication de la souris...
		;---------------------------------------------
CHK_MOUSE:
		; RÈforme du systËme qui consiste a une nouvelle
		; routine utilisÈ pour dessiner ‡ mÍme le
		; WORK GRILD!

		mov di,offset FULLX
		mov ax,3
		int 33h
		mov [di],cx
		mov [di+2],dx

		shr cx,4		; …quivalent de la routine
		shr dx,3                ; WBUT.

		; Is mouse in grild?
		cmp bl,0
		je MAIN_LOOP
		cmp cl,7		; CL=7 ?
		ja NOTINGRILD           ; CL>7 THEN NOTINGRILD
		cmp dl,7                ; DL=7 ?
		ja NOTINGRILD           ; DL>7 THEN NOTINGRILD

		; Si la souris est dans la grille d'Èdition alors
		; procÈdons ‡ la vÈrification des positions antÈrieures.

		mov si,offset LDX	; SI=LDX
		cmp cl,[si]             ; CL=[LDX]?
		jne NOTSAME		; si diffÈrent -> NOTSAME

		cmp dl,[si+1]           ; DL=[LDX]?
		je MAIN_LOOP            ; si Ègale -> MAIN_LOOP

NOTSAME:        ;cmp bl,0    		; BL=0 ?
		;je MAIN_LOOP            ; si Ègale -> MAIN_LOOP

		; Dessinons librement dans la grille d'Èdition,
		; maintenant que tout est OK!

		push cx			; sauvegarde CX
		push dx                 ; sauvegarde DX

		mov al,0ah		; AL=0ah
		mul dl			; AX=0ah*MOUSEY
		rol ax,8		; AX=MOUSEY*0a00h
		rol cx,3		; CX=MOUSEX*8
		mov di,ax		; DI=MOUSEY*0a00h
		add di,cx               ; DI=MOUSEY*0a00h+MOUSEX*8

		mov si,offset CD	; SI= CD
		mov al,[si]             ; AL= [CD]
		mov ah,al               ; AX= [CD]+[CD]*256
		push ax                 ; sauvegarde AX
		rol eax,16              ; EAX= AX*2^16
		pop ax                  ; restaure AX

		HMOUSE			; cache la souris
		mov bx,8
DRWSQRB:	mov cx,2
DRWSQRA:	mov gs:[di],eax
		add di,4
		loop DRWSQRA

		add di,140h-8
		mov cx,bx
		dec bx
		loop DRWSQRB

		pop dx			; restaure DX
		pop cx                  ; restaure CX

		mov di,offset LDX
		mov [di],cl
		mov [di+1],dl

		push ax
		mov si,offset FONT	; SI=FONT
		mov al,[si]             ; AL=[FONT]
		mov ah,0                ; AH=0
		rol ax,6                ; AX=[FONT]*64
		rol dx,3		; DX=DX*8

		mov di,ax
		add di,cx
		add di,dx

		pop ax
		mov dx,DATA
		mov fs,dx
		mov fs:[di],al

		call DYSPLAY_WORK_GRILD
		SMOUSE
		jmp MAIN_LOOP

		; Mouse is not in editing grild! Where is the mouse?
		; Identifying the mouse's actual position.
NOTINGRILD:
		cmp cl,40-17		; IF CL>=(40-17)
		jae MAYBEAFONT          ; THEN MAYBEAFONT

		; A ce point-ci, je dois conserver l'ancien dispositif
		; parce qu'il est encore nÈcessaire.

		mov si,offset LDX	; SI=LDX
		cmp cl,[si]             ; CL=[LDX]?
		jne NOTSAME2		; si diffÈrent -> NOTSAME

		cmp dl,[si+1]           ; DL=[LDX]?
		je MAIN_LOOP            ; si Ègale -> MAIN_LOOP

NOTSAME2:       ;cmp bl,0    		; BL=0 ?
		;je MAIN_LOOP            ; si Ègale -> MAIN_LOOP

		mov si,offset LDX
		mov [si],cl
		mov [si+1],dl

		; Ceci vÈrifie les autres positions. Actuellement,
		; seulement la palette sera vÈrifiÈe.

		cmp cl,11
		jb MAIN_LOOP
		cmp cl,11+8
		jae MAIN_LOOP
		cmp dl,5
		jne MAIN_LOOP

		mov si,offset BC
		mov al,[si]
		sub cl,11
		add al,cl
		jmp SAVENEWCLR

MAYBEAFONT:     cmp bl,0
		je MAIN_LOOP
		cmp cl,39
		je MAIN_LOOP
		cmp dl,0
		je MAIN_LOOP
		cmp dl,17
		jae MAIN_LOOP

		; Actionnons le nouveau dispositif de protection
		; en cas de conflit d˚ au systËme qui vient d'Ítre
		; rajouter.

		mov si,offset FULLX
		mov di,offset LASTX

		mov ax,[si]
		cmp ax,[di]
		jne NOTSAME_NEW

		mov ax,[si+2]
		cmp ax,[di+2]
		jne NOTSAME_NEW
		jmp MAIN_LOOP

NOTSAME_NEW:    mov ax,[si]
		mov [di],ax

		mov ax,[si+2]
		mov [di+2],ax

		sub cx,40-17
		sub dx,1

		rol dx,4		; DX=DX*16

		mov ax,dx
		add ax,cx
		mov si,offset FONT
		mov [si],al

		cmp bx,1
		je EXTRAFX

NORMALFX:	HMOUSE
		call DYSPLAY_FONT_IN_GRILD
		SMOUSE
		jmp MAIN_LOOP

EXTRAFX:        mov si,offset FULLX
		mov ax,[si]
		ror ax,1		; AX= 2X/2
		sub ax,(40-17)*8
		and ax,7

		mov bx,[si+2]
		sub bx,8
		and bx,7
		rol bx,3

		mov si,offset FONT
		mov cl,[si]
		mov ch,0
		rol cx,6

		add cx,ax
		add cx,bx
		mov di,cx

		mov si,offset CD
		mov al,[si]

		mov dx,DATA
		mov fs,dx

		mov fs:[di],al

		HMOUSE
		call DYSPLAY_FONT_IN_GRILD
		call DYSPLAY_WORK_GRILD
		SMOUSE
		jmp MAIN_LOOP
		jmp NORMALFX



		jmp MAIN_LOOP

		;---------------------------------------------------

DECPAL:		mov si,offset BC
		mov al,[si]
		cmp al,1
		je MAIN_LOOP
		sub al,8
ADJPAL:		mov [si],al
		HMOUSE
		call DYSPLAY_COLORS_PALETTE
		SMOUSE
		jmp MAIN_LOOP

INCPAL:		mov si,offset BC
		mov al,[si]
		cmp al,1-8
		je MAIN_LOOP
		add al,8
		jmp ADJPAL

		;------------------------------------------

SHORTKEYS:	mov si,offset KEYS
		mov cx,8
CHKKEYSA:	cmp al,[si]
		je KEYSMATCH
		inc si
		loop CHKKEYSA
		jmp MAIN_LOOP

KEYSMATCH:	sub si,offset KEYS
		mov bx,si

		mov si,offset BC
		mov al,[si]
		mov ah,0
		add ax,bx

SAVENEWCLR:	mov si,offset CD
		mov [si],al

		mov si,offset LDX
		mov al,255
		mov [si],al
		mov [si+1],al
		jmp MAIN_LOOP

COLOR_BLACK:	mov al,0
		jmp SAVENEWCLR

		;--------------------------------------------------



		;***************************************************
		; Below this point are all of the major routines
		; composing this program. Some of them are essential
		; but some of them are there only as a standard.
		;***************************************************

		;----------------------------------------------
		; PRINT_SMALL
		;
		; IMPUTS:
		; [SI] source of string
		; [DI] destination on screen
		;
		; OUTPUTS:
		; print very small font
		;----------------------------------------------

PRINT_SMALL:	pusha

AGAIN_XXX:	mov al,[si]
		cmp al,0
		je ENDOFSTR
		push di
		push si

		mov si,offset ASCII_TABLE
CHKFNTA:	cmp al,[si]
		je MTCHFNT
		inc si
		jmp CHKFNTA

MTCHFNT:	sub si,offset ASCII_TABLE	; SI=SI-ASCII_TABLE
		rol si,6                        ; SI=SI*64
		add si,offset ASCII

		mov bx,8
TRSFONT2:	mov cx,4

TRSFONT1:	mov al,[si]
		mov gs:[di],al
		inc si
		inc si
		inc di
		loop TRSFONT1

		add di,140h-4
		mov cx,bx
		dec bx
		loop TRSFONT2

		pop si
		pop di
		inc si
		add di,4
		jmp AGAIN_XXX

ENDOFSTR:	popa
		ret

		;----------------------------------------------
		; PRINT_QWERTYUI
		;
		; INPUTS:NO INPUTS
		; OUTPUTS:QWERTYUI
		;
		;----------------------------------------------

PRINT_QWERTYUI: pusha

		mov cx,8
		mov di,11*8+6*0a00h
		mov si,offset QWERTYUI
PRINTMORE:	mov al,[si]
		call PRINT_ONE
		inc si
		add di,8
		loop PRINTMORE
		popa
		ret

		;----------------------------------------------
		; PRINT_WHITE_LINES
		;
		; INPUTS:NO INPUTS
		; OUTPUTS: #...#
		;
		;----------------------------------------------

PRINT_WHITE_LINES: pusha
		 mov al,"#"
		 mov bx,8*8
		 mov dx,8*0a00h

		 mov cx,9
PWLS:		 mov di,bx
		 call PRINT_ONE
		 mov di,dx
		 call PRINT_ONE
		 add bx,0a00h
		 add dx,8
		 loop PWLS
		 popa
		 ret

		;----------------------------------------------
		; PRINT_ONE
		;
		; INPUTS:
		; AL : FONT NUMBER TO PRINT (ASCII)
		; DI : DESTINATION ON SCREEN
		;
		; OUTPUTS:
		; print a font (in ascii 40 character per line mode)
		;----------------------------------------------

PRINT_ONE:	pusha

		mov si,offset ASCII_TABLE
CHKPR1A:	mov ah,[si]
		cmp al,ah
		je MATCH_PR1
		inc si
		jmp CHKPR1A

MATCH_PR1:	sub si,offset ASCII_TABLE
		rol si,6
		add si,offset ASCII

		;mov dx,DATA
		;mov fs,dx

		mov bx,8
MNMB:		mov cx,2
MNMA:		mov eax,[si]
		mov gs:[di],eax
		add di,4
		add si,4
		loop MNMA

		add di,140h-8
		mov cx,bx
		dec bx
		loop MNMB

		popa
		ret

		;----------------------------------------------
		; DYSPLAY_COLORS_PALETTE
		;
		; INPUTS: NO IMPUTS
		; OUTPUTS: DYSPLAY COLORS_PALETTE
		;----------------------------------------------

DYSPLAY_COLORS_PALETTE:pusha

		call CONVENSIONS
		mov di,11*8+5*0a00h
		mov si,offset BC
		mov al,[si]

		mov dx,8
DYSPLCLR3:	mov ah,al
		push ax
		rol eax,16
		pop ax
		push di

		mov bx,8
DYSPLCLR2:	mov cx,2

DYSPLCLR1:	mov gs:[di],eax
		add di,4
		loop DYSPLCLR1

		mov cx,bx
		dec bx
		add di,140h-8
		loop DYSPLCLR2

		mov cx,dx
		dec dx
		pop di
		add di,8
		inc al
		loop DYSPLCLR3

		popa
		ret

		;----------------------------------------------
		; DYSPLAY_FONT_IN_GRILD:
		;
		; INPUTS:
		; GRILD:[FONT]*64
		;
		; OUTPUTS:
		; print font in grild
		;----------------------------------------------

DYSPLAY_FONT_IN_GRILD: pusha
		push fs

		mov dx,0a000h
		mov gs,dx

		mov dx,DATA
		mov fs,dx

		mov si,offset FONT
		mov al,[si]
		mov ah,0
		rol ax,6

		mov si,ax
		mov di,0

		mov dx,8
PFONTGD:	mov bx,8

		push di
PFONTGC:	mov al,fs:[si]
		mov ah,al
		push ax
		rol eax,16
		pop ax
		inc si

		push bx
		mov bx,8
		push di
PFONTGB:	mov cx,2

PFONTGA:	mov gs:[di],eax
		add di,4
		loop PFONTGA

		add di,140h-8
		mov cx,bx
		dec bx
		loop PFONTGB

		pop di
		pop bx
		add di,8
		mov cx,bx
		dec bx
		loop PFONTGC

		pop di
		add di,0a00h
		mov cx,dx
		dec dx
		loop PFONTGD

		pop fs
		popa
		ret

		;----------------------------------------------
		; DYSPLAY_WORK_GRILD:
		; INPUTS:
		; no inputs
		; OUTPUTS:
		; printed word grild
		;----------------------------------------------

DYSPLAY_WORK_GRILD: pusha
		push ds
		push gs

		mov si,0
		mov di,140h-(17*8)+0a00h

		mov dx,DATA
		mov ds,dx
		mov dx,0a000h
		mov gs,dx
		call DYSPLAY_GRILD

		pop gs
		pop ds
		popa
		ret

		; ---------------------------------------------
		; DYSPLAY GRILD
		; INPUTS:
		; [DS:SI] SOURCE FOR GRILD INFORMATIONS
		; [GS:DI] DESTINATION FOR GRILD
		;
		; OUTPUTS:
		; printed grild on the screen
		;--------------------------------------------

DYSPLAY_GRILD:	pusha
		mov dx,16
DYSPLGRLD:	push di

		mov bx,16
DYSPLGRLC:	push bx
		push di

		mov bx,8
DYSPLGRLB:	mov cx,8/4
DYSPLGRLA:	mov eax,[si]
		mov gs:[di],eax
		add si,4
		add di,4
		loop DYSPLGRLA

		add di,140h-8
		mov cx,bx
		dec bx
		loop DYSPLGRLB

		pop di
		pop bx
		add di,8

		mov cx,bx
		dec bx
		loop DYSPLGRLC

		pop di
		add di,0a00h
		mov cx,dx
		dec dx
		loop DYSPLGRLD

		popa
		ret

	       ; --------------------------------------------
	       ; WBUT
	       ; INPUTS:
	       ; no inputs
	       ; OUTPUTS:
	       ; BX: button ; CX: mouse x ; DX: mouse y
	       ; --------------------------------------------

WBUT:          push ax
	       mov ax,3
	       int 33h
	       shr cx,4
	       shr dx,3
	       pop ax
	       ret

	       ;-----------------------------------------------
	       ; MêLO_PAINT
	       ; INPUTS:
	       ; eax:color
	       ; OUTPUTS:
	       ; full screen redraw
	       ;---------------------------------------------

MELO_PAINT:    jmp ML_PAINT
CLS:           mov eax,0
ML_PAINT:      pusha
	       mov cx,65536/4
	       xor di,di
ML_PAINT_DRAW: mov gs:[di],eax
	       add di,4
	       loop ML_PAINT_DRAW
	       popa
	       ret

	       ;----------------------------------------------
	       ; CONVENSIONS
	       ; INPUTS:
	       ; no inputs
	       ; OUTPUTS:
	       ; DS:DATA,ES:MEM1,FS:MEM2,GS:a000h
	       ;------------------------------------------------

CONVENSIONS:   push dx
	       mov dx,DATA
	       mov ds,dx
	       ;mov dx,MEM1
	       ;mov es,dx
	       ;mov dx,MEM2
	       ;mov fs,dx
	       mov dx,0a000h
	       mov gs,dx
	       pop dx
	       ret


	       ;-------------------------------------------------
	       ; QUIT / NOT_FOUND
	       ; INPUTS:
	       ; no inputs
	       ; OUTPUTS:
	       ; nothing/Warning: missing or write protected file
	       ;-------------------------------------------------

QUIT:          ;mov ah,1
	       ;int 21h

	       mov dx,DATA
	       mov ds,dx
	       mov si,offset OLD_VIDEO_MODE
	       xor ax,ax
	       mov al,[si]
	       int 10h
	       xor al,al
	       mov ah,4ch    ; retourne au DOS
	       int 21h

NOT_FOUND:     mov dx,DATA
	       mov ds,dx
	       mov si,offset OLD_VIDEO_MODE
	       xor ax,ax
	       mov al,[si]
	       int 10h
	       mov ah,9
	       mov dx,DATA
	       mov ds,dx
	       mov dx,offset FILENAME
	       int 21h
	       mov al,1
	       mov ah,4ch
	       int 21h

	  ;----------------------------------------------------

MAKEPATH:      pusha
	       mov ax,DATA
	       mov ds,ax
	       mov si,offset PATH
	       mov di,offset FILENAME
TRANS_PATH:    mov al,[si]
	       mov [di],al
	       cmp al,0
	       je AFTERPATH
	       inc si
	       inc di
	       jmp TRANS_PATH
AFTERPATH:     mov si,dx
AFTER_PATH:    mov al,[si]
	       mov [di],al
	       cmp al,0
	       je ENDPATH
	       inc si
	       inc di
	       jmp AFTER_PATH
ENDPATH:       popa
	       mov ax,DATA
	       mov ds,ax
	       mov dx,offset FILENAME
	       ret

;--------------------------------------------------------

LOADOLD:  call MAKEPATH
	  push bx      ; offset destination
	  push cx      ; nombre d'octets a lire
	  push es      ; segment destination
	  mov al,0
	  mov ah,3dh
	  int 21h
	  jc NOT_FOUND

	  push ax      ; sauvegarde du code d'acces au fichier
	  mov bx,ax    ; insere le code d'acces dans BX
	  xor cx,cx    ; deplace le pointeur du fichier
	  mov dx,7
	  mov al,0     ; relatif au debut du fichier
	  mov ah,42h
	  int 21h
	  jc NOT_FOUND

	  pop bx         ; retire le code d'acces au fichier
	  pop ds       ; segment destination
	  pop cx       ; nombre d'octets a lire
	  pop dx       ; offset destination
	  push bx      ; sauvegarde le code d'acces
	  mov ah,3fh
	  int 21h
	  jc NOT_FOUND

	  pop bx       ; retire le code d'acces au fichier
	  mov ah,3eh
	  int 21h
	  ret


;-------------------------------------------------------

LOADNEW:  call MAKEPATH
	  push bx       ; offset destination
	  push cx       ; nombre d'octets a lire
	  push es       ; segment destination
	  mov al,0
	  mov ah,3dh
	  int 21h
	  jc NOT_FOUND

	  mov bx,ax     ; code d'acces
	  pop ds        ; segment destination
	  pop cx        ; nombre d'octets a lire
	  pop dx        ; offset destination
	  push bx
	  mov ah,3fh
	  int 21h
	  jc NOT_FOUND

	  pop bx        ; fermeture du fichier
	  mov ah,3eh
	  int 21h
	  ret

	  ;--------------------------------------------------------------

LOADNEW2:  call MAKEPATH
	  push bx       ; offset destination
	  push cx       ; nombre d'octets a lire
	  push es       ; segment destination
	  mov al,0
	  mov ah,3dh
	  int 21h
	  jc RESTART2

	  mov bx,ax     ; code d'acces
	  pop ds        ; segment destination
	  pop cx        ; nombre d'octets a lire
	  pop dx        ; offset destination
	  push bx
	  mov ah,3fh
	  int 21h
	  jc RESTART2

	  pop bx        ; fermeture du fichier
	  mov ah,3eh
	  int 21h
	  jc RESTART2
	  ret


		    ;-----------------------------------------
		    ; GETAX
		    ; INPUTS:
		    ; no inputs
		    ; OUTPUS:
		    ; return a caracter from the buffer
		    ;-----------------------------------------

GETAX:              ;call NUM_LOCK
		    push bx
		    push dx
		    push ds
		    mov ax,0
		    mov dx,40h
		    mov ds,dx
		    mov dx,word ptr ds:[1ch]
		    mov bx,word ptr ds:[1ah]
		    cmp dx,bx
		    jz GETOUT
		    mov ax,[bx]
		    mov ds:[1ah],dx
GETOUT:             cmp al,27
		    je QUIT
		    pop ds
		    pop dx
		    pop bx
		    call CONVENSIONS
		    ret

	    ;-------------------------------------
	       ; NUM_LOCK
	       ; INPUTS:
	       ; no inputs
	       ; OUTPUTS
	       ; NUM LOCK:    true
	       ; CAPS LOCK:   false
	       ; SCROLL LOCK: false
	       ;------------------------------------

NUM_LOCK:      pusha
	       push ds
	       mov dx,0
	       mov ds,dx
	       mov si,1047
	       mov al,[si]
	       and al,255-64-16
	       or al,32
	       mov [si],al
	       pop si
	       popa
	       ret

	       ;-------------------------------------

RESTART2:       mov sp,bp
		call CONVENSIONS
		mov eax,00060006h
		call MELO_PAINT
		call PRINT_WHITE_LINES
		call PRINT_QWERTYUI
		call DYSPLAY_WORK_GRILD
		call DYSPLAY_FONT_IN_GRILD
		call DYSPLAY_COLORS_PALETTE

		mov si,offset IO_ERROR
		mov di,offset 12*0a00h
MMD:		mov al,[si]
		cmp al,0
		je SMOUSE2
		call PRINT_ONE
		inc si
		add di,8
		jmp MMD
SMOUSE2:	SMOUSE
		jmp MAIN_LOOP


;-----------------------------------------------------------------------

		; Make a rotation on the FNT Grild

;-----------------------------------------------------------------------


F6_Key:

		mov si,Grild
                mov di,offset Image + 15* SeizeCases+ 7*8

                mov fx,16
TQ4:            push di			; BEGIN 4
                push si

                mov ex,8		; BEGIN 3
TQ3:            push di
                push si

                mov dx,16		; BEGIN 2
TQ2:            push di
                push si

		mov cx,8		; BEGIN 1
TQ1:            mov al,[si]
                mov [di],al
                inc si
                sub di,8
                loop TQ1		; END 1

                pop si
                pop di
                sub di,SeizeCases
                add si,UneCase
                set cx,dx
                dec dx
		loop TQ2		; END 2

        	pop si
                pop di
                add si,8
                inc di
                set cx,ex
                dec ex
                loop TQ3  		; END 3

		pop si
                pop di
                add si,SeizeCases
                add di,UneCase
                set cx,fx
                dec fx
                loop TQ4		; END 4

                copymem DATA,Grild, DATA, offset Image, 16384


         	Hmouse
		jmp Restart


;------------------------------------------------------------------------

		; Flip FNT Grild LEFT/RIGHT

;------------------------------------------------------------------------


F7_key:

		set <ds>,DATA

                mov si,Grild
                mov di,offset Image + (15 * 64) + 7


                mov bx,0

                mov gx,16		; **4 BEGIN

Trn2d:          push di
                push si

                mov fx,8		; **3 BEGIN

Trn2c:          push di
                push si

                mov ex,16		; **2 BEGIN
Trn2b:          push di
                push si


                mov cx,8		; **1 BEGIN
Trn2:           mov al,[si+bx]
                mov [di+bx],al
                inc si
		dec di
                loop Trn2		; **1 END

                pop si
                pop di
                add si,UneCase
                sub di,UneCase
                set cx,ex
                dec ex
                loop Trn2b          	; **2 END

          	pop si
                pop di
                add si,8
                add di,8
		set cx,fx
                dec fx
                loop Trn2c		; **3 END


		pop si
                pop di
                add bx,SeizeCases
                set cx,gx
                dec gx
                loop Trn2d		; **4 END


                copymem DATA,Grild, DATA, offset Image, 16384


		Hmouse
		jmp Restart


;----------------------------------------------------------------------
			; Flip FNT Grild UP/DN
;----------------------------------------------------------------------


F8_key:

		set <ds>,DATA

		mov si,Grild
                mov di,offset Image + 15* SeizeCases

                mov ex,16

Nx16Sqrs:
                ; Transfer
                push di
                push si

                ; Transfer une Ligne de case de haut a en bas
		mov fx,8
		mov bx,7*8

Trn1b:          push di
                push si
		mov cx,16
Trn1:           mov eax,[si]
		mov [di+bx],eax
                mov eax,[si+4]
                mov [di+bx+4],eax
		add si,UneCase
                add di,UneCase
                loop Trn1

                pop si
                pop di
                add si,8
		sub bx,8
                set cx,fx
                dec fx
                loop Trn1b

        	; Transfer d'une ligne de haute ‡ en bas terminer

                pop si
                pop di
                add si,SeizeCases
                sub di,SeizeCases

                set cx,ex
                dec ex
                loop Nx16Sqrs

                copymem DATA,Grild, DATA, offset Image, 16384

		Hmouse
		jmp Restart


;----------------------------------------------------------------



; -----------------------FIN DU PROGRAMME-----------------------
VLAMITS    ENDP                           ; Fin de la procedure
CODE ENDS                                ; Fin du programme
END     VLAMITS                           ; Point d'entree
;---------------------------------------------------------------
