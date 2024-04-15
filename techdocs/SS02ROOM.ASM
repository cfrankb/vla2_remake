;----------------------------------------------------------------
;       STATICS SYSTEM V2 ROOM EDITOR V1.0
;       by Francois Blanchette
;----------------------------------------------------------------

INCLUDE C:\MASM61\LISTING\SSFSMAC.INC
INCLUDE C:\MASM61\LISTING\IOSYSTEM.INC

; Enables all externals definitions...
UseStatV2	; 94STATV2.ASM
UseRepV2	; 94REPV2.ASM

;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK 'STACK'
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------

TestVar		MACRO Var,Value,Text
Local		OUT_

		cmp Var,Value
                jne OUT_
                mov dx,Text
                jmp SendErrorMessage

OUT_:

		ENDM

;----------------------------------------------------------------

HexFrameExtender MACRO Value, Frame
Local		ALNotABC, ALNotABC_

                pushall

                set <ds>,DATA

                mov di, Frame


                mov al,Value
                and al,15
                add al,30h

                cmp al,3ah
                jb ALNotABC
                sub al,3ah
                add al,65
ALNotABC:	mov [di+1], al


		mov al,Value
                shr al,4
                and al,15
                add al,30h

                cmp al,3ah
                jb ALNotABC_
                sub al,3ah
                add al,65
ALNotABC_:	mov [di],al

                popall
                ENDM

;------------------------------------------------------------------

WriteToScreen 	MACRO X,Y, Text
Local		NextLetter,LookMore,MatchFound,DFont, Out_

		pushall

                ;set <gs>, 0a000h
                set <gs>,screen
                set <ds>, DATA
                mov si,Text

                ; Normal font size...

                mov di,x*8+y*0a00h

NextLetter:     mov al,[si]
                cmp al,0
                je Out_
                cmp al,13
                je Out_

                inc si

                mov bx, offset ASCII_TABLE
LookMore:       cmp [bx],al
                je MatchFound

                inc bx
                jmp LookMore

MatchFound:	sub bx,offset ASCII_TABLE
                shl bx,6
                add bx,offset LETTERS

                push di

                mov cx,8

DFont:          mov eax,[bx]
                mov gs:[di],eax
                mov eax,[bx+4]
                mov gs:[di+4],eax
                add di,140h
                add bx,8
                loop DFont

          	pop di
                add di,8

                jmp NextLetter

Out_:

                popall
		ENDM

;----------------------------------------------------------------

WriteToScreen80 MACRO X,Y, Text
Local		NextLetter,LookMore,MatchFound,DFont, Out_,Q1,Q2

		pushall

                ;set <gs>, 0a000h
                set gs,Screen
                set <ds>, DATA
                mov si,Text

                ; Normal font size...

                mov di,x*8+y*0a00h

NextLetter:     mov al,[si]
                cmp al,0
                je Out_
                cmp al,13
                je Out_

                inc si

                mov bx, offset ASCII_TABLE
LookMore:       cmp [bx],al
                je MatchFound

                inc bx
                jmp LookMore

MatchFound:	sub bx,offset ASCII_TABLE
                shl bx,6
                add bx,offset LETTERS

                push di

                mov dx,8

Q2:             mov cx,4

DFont:          mov al,[bx]
                cmp al,15
                jne Q1
                dec al
Q1:
                mov gs:[di],al

		inc di
                inc bx
                inc bx
                loop DFont

		add di,140h-4
		mov cx,dx
                dec dx
                loop Q2

	 	pop di
                add di,8/2

                jmp NextLetter

Out_:

                popall
		ENDM

;----------------------------------------------------------------

DATA      SEGMENT PUBLIC 'DATA'
VersionNo	db "SSV2 ROOM EDITOR V1.0 "
		db "(C) 1995 Francois Blanchette."

COPYRIGHT       db 13,10
		db "SSV2 Room Editor V1.0 ",13,10
		db "(C) 1995 Francois Blanchette.",13,10
                db 13,10

                db "Please select an option:",13,10
                db 13,10
                db "L. Load an existing room",13,10
                db "C. Creat a new room",13,10
                db 13,10,"$"


LoadScrTxt	db "Name of existing .SCR:$"
CreatScrTxt	db "Name of new .SCR file:$"
StoParentTxt	db 13,10
		db "Name of .STO parent  :$"

ASCII_TABLE     db " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"
		db "#$%&*().!,/?:;=+-{}[]\|`~<>1234567890",0,-1

align 4
LETTERS		db (offset Letters - offset ASCII_TABLE)*64 DUP (0)

		align 2
		db 8,0
NameOfScr	db 16 DUP (1)
		db 8,0
NameOfSto	db 16 DUP (2)
		dw 0
NameOfIms	db 16 DUP (3)
_SCR		db ".SCR",0,"$"
_STO		db ".STO",0,"$"

Coordinates	db "X=00; Y=00; MX=00; MY=00;",0

ScriptNoTxt	db "Script Entry  :0000",0
ImaNameTxt	db 81 DUP (0)
DysplayAttTxt	db "Dysplay Att.  :00;",0
ObjStatTxt	db "Obj. Status   :00;",0
Unused1txt	db "Unused #1=00;",0
Unused2Txt	db "Unused #2=00;",0

_ObjNoTxt	db "Obj No.       :0000",0
_ImaNameTxt	db 81 DUP (0)
_DysplayAttTxt	db "Dysplay Att.  :00",0
_ObjStatTxt	db "Obj. Status   :00",0

Color		db 1

align 2

ScrFileId	dw 0
NulWord 	dw 0

;ScriptSize	dw 0
ScrPtr		dw 0
ScrEnd		dw 0
StoPtr		dw 0

; Information put-in byte AUTO-FILL	(SCRIPT INFO)
align 4
DysplayAtt	db 0
ObjStat		db 0
Unused		dw 0
ImaNo		dw 0
ObjX		db 2
ObjY		db 2

; Information put-in for STO DEFS
_DysplayAtt	db 0
_ObjStat	db 0
_ImaNo		dw 0

ScrX		db 0
ScrY		db 0

ImaLen		dw 0
ImaHei		dw 0
CurrentIma	dw 0
CurrentSto	dw 0
LastIma		dw 0
LastSto		dw 0
NamePtr	        dw 0

EntryNo		dw 0		; calculated using ScrPtr

DATA   ENDS

;--------------------------------------------------------------------

ScrFile		EQU word ptr ScrFileId
VersionNoLenght	EQU offset Copyright - offset VersionNo

;--------------------------------------------------------------------

LIBRAIRY SEGMENT 'LIBRAIRY' PUBLIC
LIBRAIRY ENDS

FONT SEGMENT 'FONT' PUBLIC
FONT ENDS

STATICS SEGMENT 'STATICS' PUBLIC
STATICS ENDS

SCREEN SEGMENT 'SCREEN' PUBLIC
SCREEN ENDS

CODE SEGMENT READONLY PUBLIC 'CODE'

.386

DysplayMenu PROC NEAR

		ClearScreen
		Locate 0,0
                Print offset Copyright
                ret

DysplayMenu ENDP

AskOption PROC NEAR

		call Getax
		ifedo al,"l",LoadScrLocal
                ifedo al,"L",LoadScrLocal
                ifedo al,"c",CreatScr
                ifedo al,"C",CreatScr
                jmp AskOption

LoadScrLocal:	Print offset LoadScrTxt
		Input offset NameOfScr-2,8

                set si,offset _SCR
                set di,offset NameOfScr
                call AddExt

                ; Charge du fichier Script en mémoire...

                HOpenForRead offset NameOfScr, ScrFile
                HReadFile DATA, offset ScriptSize, 2, ScrFile
                HReadFile DATA, offset NameOfSto, 16, ScrFile
                HReadFile LIBRAIRY,offset ScrDefs,word ptr ScriptSize,ScrFile
                HClose ScrFile

                jmp GetScrToMem

CreatScr:

                ; Demand à l'utilisateur le nom du nouveau fichier
                ; script.

		Print offset CreatScrTxt
		Input offset NameOfScr-2,8

                set si,offset _SCR
                set di,offset NameOfScr
                call AddExt

                ; Demande le nom du fichier .STO parent du fichier
                ; script.

                Print offset StoParentTxt
                Input offset NameOfSto-2,8

                set si,offset _STO
                set di,offset NameOfSto
                call AddExt

                HCreat offset NameOfScr, ScrFile          ; Crée le fichier
                					  ; script.

                HWrite DATA, offset NulWord, 2, ScrFile   ; Écris dans le
                					  ; fichier script
                                                          ; un double
                                                          ; octet nul.

                HWrite DATA, offset NameOfSto, 16, ScrFile; Écris
                					  ; dans le fichier
                                                          ; script le nom
                                                          ; du fichier .STO
                                                          ; parent


                HWrite DATA, offset VersionNo, VersionNoLenght, ScrFile

		HClose ScrFile				  ; Ferme le fichier
                					  ; scripte



GetScrToMem:	HOpenForRead offset NameOfSto, ScrFile	  ; Ouvre le
							  ; fichier .STO
                                                          ; en lecture
                                                          ; seule.

		HReadFile DATA, offset NameOfIms-2, 18, ScrFile ; Lire le nom
                					  ; du fichier
                                                          ; .IMS parent
                                                          ; du .STO

                HReadFile LIBRAIRY,offset StoDefs,word ptr [NameOfIms-2], ScrFile
							  ; Effectue
                                                          ; la lecture des
                                                          ; des definitions
                                                          ; .STO en memoire.


                HClose ScrFile				  ; Ferme le fichier
                					  ; .STO


                HLoadIms offset NameOfIms			  ; Charge en
                                           		  ; memoire un
                                                          ; fichier
                                                          ; format .IMS

		ret


AddExt:
		mov bl,byte ptr [di-1]
                nul bh

                add di,bx
                jmp EXT

		jmp QUIT


AskOption ENDP



;-----------------------------------------------------------------------

InitScrManager PROC NEAR


		set DS, DATA
		;mov word ptr ScrPtr, offset ScrDefs
		movw word ptr ScrEnd, word ptr ScriptSize
                add word ptr ScrEnd, offset ScrDefs

                ; modification 18/12/94
                movw word ptr ScrPtr, word ptr ScrEnd

		ret

InitScrManager ENDP

;-----------------------------------------------------------------------

ScrManager  PROC

                set ds,DATA
		set es,LIBRAIRY
                set gs,0a000h

		mov word ptr CurrentSto,0
ChangeEntry:    call AutoFillInfoGrild
                call AjustScreenToIma

Update:		movw word ptr CurrentIma, word ptr ImaNo
                call ImaSizeFiller

                call InsureImaOnScr
		call DrawScreen_
                call DrawTexts

                copyseg 0a000h,Screen
                call DrawIma

XX:             call DrawImaBorders
		call Getax

                ifsedo al,"=", SaveScr
                ifsedo al,"+", SaveScr

                ifedo al,"8", ImaUp	; move IMA Up
                ifedo al,"2", ImaDn	; move IMA Dn
                ifedo al,"4", ImaLf	; move IMA Lf
                ifedo al,"6", ImaRg	; move IMA Rg

                ifedo ah,72, DecMY	; up
                ifedo ah,80, IncMY	; dn
                ifedo ah,75, DecMx	; lf
                ifedo ah,76, incMx	; rg

                ifedo al,13, SaveEntry

                ifedo al,"n", NxEntry
                ifedo al,"N", NxEntry
                ifedo al,"b", BkEntry
                ifedo al,"B", BkEntry

                ifedo al,"a", DecUn1
                ifedo al,"A", DecUn1
                ifedo al,"s", IncUn1
                ifedo al,"S", IncUn1

                ifedo al,"k", DecUn2
                ifedo al,"K", DecUn2
		ifedo al,"l", IncUn2
                ifedo al,"L", IncUn2
                ifedo ah,83,DelScr
                ifedo al,"/",SInsScr
                ifedo al," ",SaveEntryNx

                ifedo ah,59,ToFirstScr	; F1
                ifedo ah,60,ToLastScr
                ifedo ah,61,ToLastScr
                ifedo ah,62,ToLastScr   ; F4

                cmp al,"c"
                jsem StoManager,Update

                cmp al,"C"
                jsem StoManager,Update


                jmp XX

;------------------------------------------------------------------


ToFirstScr:	mov word ptr ScrPtr, offset ScrDefs
		jmp ChangeEntry

ToLastScr:	movw word ptr ScrPtr, word ptr ScrEnd
		jmp ChangeEntry

;-----------------------------------------------------------------

InsureImaOnScr:

ChkSelonX:		mov al,byte ptr ScrX
                        add al,byte ptr ImaLen
                        cmp al,40
                        jbe OkSelonX

                        dec byte ptr ScrX
                        inc byte ptr MX
                        jmp ChkSelonX

OkSelonX:		mov al,byte ptr ScrY
			add al,byte ptr ImaHei
                        cmp al,20
                        jbe OkSelonY

                        Dec byte ptr ScrY
                        inc byte ptr MY
                        jmp OkSelonX

OkSelonY:		ret

;-------------------------------------------------------------------

SaveEntryNx:   	set es,Librairy

		mov di,word ptr ScrPtr

                mov al,byte ptr MX
                add al,byte ptr ScrX
                mov byte ptr ObjX,al

                mov al,byte ptr MY
                add al,byte ptr ScrY
                mov byte ptr ObjY,al

                mov eax,dword ptr DysplayAtt
                mov es:[di],eax
                mov eax,dword ptr DysplayAtt+4
                mov es:[di+4],eax

                cmpw word ptr ScrPtr, word ptr ScrEnd
                je SEN_LE

                add word ptr ScrPtr,8
                jmp ChangeEntry

Sen_Le:		add word ptr ScrPtr,8
		add word ptr ScriptSize,8
                add word ptr ScrEnd,8
                jmp ChangeEntry

;----------------------------------------------------------------------

SInsScr:	cmpw word ptr ScrPtr, word ptr ScrEnd
		je SaveEntry

		mov cx, word ptr ScrEnd
                sub cx, word ptr ScrPtr
                shr cx,3

                set es,LIBRAIRY

	        mov si, word ptr ScrEnd
SDoInsScr:      mov eax, es:[si]
                mov es:[si+8],eax
                mov eax, es:[si+4]
                mov es:[si+12],eax

                sub si,8
                loop SDoInsScr

                add word ptr ScriptSize,8
                add word ptr ScrEnd,8


		jmp SaveEntryNx

;------------------------------------------------------------------------

DelScr:		cmpw word ptr ScrPtr, word ptr ScrEnd
		je XX

                mov cx, word ptr ScrEnd
                sub cx, word ptr ScrPtr
                ;sub cx, offset ScrDefs
                shr cx,3

                set es,LIBRAIRY

	        mov di, word ptr ScrPtr
DoDelScr:       mov eax, es:[di+8]
                mov es:[di],eax
                mov eax, es:[di+8+4]
                mov es:[di+4],eax

                add di,8
                loop DoDelScr

                sub word ptr ScriptSize,8
                sub word ptr ScrEnd,8

                jmp ChangeEntry

;---------------------------------------------------------------

DecUn1:		ifedo byte ptr Unused,0, XX
		dec byte ptr Unused
                call DrawTexts
                copyseg 0a000h,SCREEN
		call DrawIma
                jmp XX

DecUn2:		ifedo byte ptr Unused+1,0,XX
		dec byte ptr UnUsed+1
                call DrawTexts
                copyseg 0a000h,SCREEN
                call DrawIma
                jmp XX

IncUn1:		ifedo byte ptr Unused,255,XX
		inc byte ptr Unused
                call DrawTexts
                copyseg 0a000h,SCREEN
                call DrawIma
                jmp XX

IncUn2:		ifedo byte ptr Unused+1,255,XX
		inc byte ptr Unused+1
                call DrawTexts
                copyseg 0a000h,SCREEN
                call DrawIma
                jmp XX

;------------------------------------------------------------------
NxEntry:     	cmpw word ptr ScrPtr, word ptr ScrEnd
		je XX

                add word ptr ScrPtr,8
		jmp ChangeEntry

;--------------------------------------------------------------------

BkEntry:        ifedo word ptr ScrPtr, offset ScrDefs,XX

		sub word ptr ScrPtr,8
                jmp ChangeEntry

;------------------------------------------------------------------

		; Sauvegarde de l'image en mémoire
SaveEntry:      mov al,byte ptr Mx
		add al,byte ptr ScrX
		mov byte ptr ObjX, al

                mov al,byte ptr My
                add al,byte ptr ScrY
                mov byte ptr ObjY,al

		copymem LIBRAIRY, word ptr ScrPtr, DATA, offset DysplayAtt,8

                cmpw word ptr ScrPtr, word ptr ScrEnd
                jne Update

                add word ptr ScrEnd,+8
                add word ptr ScrPtr,+8
                add word ptr ScriptSize, 8

                jmp Update

;------------------------------------------------------------------

ImaUp:		ifedo byte ptr ScrY,0, DecMy
		dec byte ptr ScrY
                jmp Update

ImaDn:          ifedo byte ptr ScrY, 24, IncMy
		inc byte ptr ScrY
                jmp Update

ImaLf:		ifedo byte ptr ScrX,0, DecMx
		dec byte ptr ScrX
                jmp Update

ImaRg:          ifedo byte ptr ScrX,39, IncMx
		inc byte ptr ScrX
                jmp Update


;-----------------------------------------------------------------

DecMy:		ifedo byte ptr My,0, XX
		dec byte ptr My
                jmp Update

IncMy:		ifedo byte ptr My, 255, XX
		inc byte ptr My
                jmp Update

DecMx:		ifedo byte ptr Mx,0, XX
		dec byte ptr Mx
                jmp Update

IncMx:		ifedo byte ptr Mx,255, XX
		inc byte ptr Mx
                jmp Update

ScrManager ENDP

		;--------------------------------------------------------


AjustScreenToIma PROC NEAR

                pushall

                mov byte ptr MX,0
                mov byte ptr MY,0
                movb byte ptr ScrX,byte ptr ObjX
                movb byte ptr ScrY,byte ptr ObjY

                cmp byte ptr ObjX, 39
                jbe OnScrSelonX

                mov al,byte ptr ObjX
		sub al,20
                mov byte ptr MX,al
                mov byte ptr ScrX,20

OnScrSelonX:

		cmp byte ptr ObjY,20
                jbe OnScrSelonY

                mov al,byte ptr ObjY
                sub al,10
                mov byte ptr MY,al
                mov byte ptr ScrY,10

OnScrSelonY:

                popall

		ret

AjustScreenToIma ENDP


		;----------------------------------------------------
AutoFillInfoGrild PROC NEAR

		pushall
		mov si,word ptr ScrPtr
                movb byte ptr DysplayAtt, es:[si]
                movb byte ptr ObjStat, es:[si+1]
                movw word ptr ImaNo, es:[si+4]
                movw word ptr Unused, es:[si+2]
                movw word ptr Objx, es:[si+6]
                popall
                ret

AutoFillInfoGrild ENDP

		;----------------------------------------------------

ImaSizeFiller PROC NEAR

		pushall

                mov cx,word ptr CurrentIma
                xor si,si

                ifedo cx,0, FoundImaSize
LookImaSize:    mov si,es:[si]
                loop LookImaSize

FoundImaSize:	movb byte ptr ImaLen, byte ptr es:[si+2]
		movb byte ptr ImaHei, byte ptr es:[si+4]

                popall
                ret


ImaSizeFiller ENDP

;-----------------------------------------------------------------------

SaveScr 	PROC NEAR
		Hcreat offset NameOfScr, ScrFile
		HWrite DATA, offset ScriptSize, 2, ScrFile
                HWrite DATA, offset NameOfSto, 16, ScrFile
                HWrite LIBRAIRY,offset ScrDefs, word ptr ScriptSize, ScrFile
                HWrite DATA, offset VersionNo, VersionNoLenght, ScrFile
                HClose ScrFile
                ret

SaveScr		ENDP
;-------------------------------------------------------------------


DrawIma PROC NEAR

		pushall

		mov al,byte ptr ScrY
                mov ah,0ah
                mul ah
                shl ax,8
                mov di,ax

                mov al,byte ptr ScrX
                nul ah
                shl ax,3
                add di,ax

ComDI:		set ES, LIBRAIRY
		set GS, 0a000h

                xor si,si
                mov bx, word ptr CurrentIma
                ifedo bx,0, FoundIma
                mov cx,bx
ChkImaAgain:    mov si,word ptr es:[si]
                loop ChkImaAgain

FoundIma:	;movw hx, word ptr es:[si+4]

		movw hx, word ptr ImaHei
                ;dec word ptr hx
                ;inc word ptr hx
                mov bp, word ptr ImaLen
                ;dec bp
                ;inc bp

                ;mov bp, word ptr es:[si+2]
		add si,4

DI04:           		       	; ** BEGIN 4
		mov lx, bp
                push di


DI03:           push di		     	; ** BEGIN 3
                mov fx,FONT
                add si,2

		mov bx, es:[si]

ChkImaPtrAgain: cmp bx,1024
                jbe FoundImaPtr

                sub bx,1024
                add fx,65536/16
                jmp ChkImaPtrAgain

FoundImaPtr:    shl bx,6
                set fs,fx

		mov dx,8                ; ** BEGIN 2
DI02: 	        mov cx,8		; ** BEGIN 1

DI01:           mov al, fs:[bx]
                or al,al
                je DoNotDraw
                mov gs:[di], al

DoNotDraw:      inc bx
                inc di
		loop DI01         ; ** END 1

                add di,140h-8
                dec dx
                or dx,dx
                jne DI02         ; ** END 2

                pop di
		add di,8
                mov cx,lx
                dec lx
                loop DI03	; *** END 3

		pop di
                add di,0a00h
                mov cx,hx
                dec hx
                loop DI04	 ; *** END 4

		popall

                ret

DrawIma ENDP

;----------------------------------------------------------------------
DrawImaBorders PROC NEAR
		pushall

		set ES, LIBRAIRY
		set GS, 0a000h

		mov al,byte ptr ScrY
                mov ah,0ah
                mul ah
                shl ax,8
                mov di,ax

                mov al,byte ptr ScrX
                nul ah
                shl ax,3
                add di,ax

                mov cx,4
                mov bx,di

DIB:            movb byte ptr gs:[di], byte ptr Color
                movb byte ptr gs:[bx], byte ptr Color
                add bx,140h
                inc di
                loop DIB


                ; Draw the lower end border of the ...

		mov al,byte ptr ScrY
                add al, byte ptr ImaHei
                dec al
                mov ah,0ah
                mul ah
                shl ax,8
                mov di,ax

                mov al,byte ptr ScrX
                add al,byte ptr ImaLen
                dec al
                nul ah
                shl ax,3
                add di,ax

                mov cx,4
                mov bx,di
                add bx,7+140h*4
                add di,140h*7+4

DIB2:           movb byte ptr gs:[di], byte ptr Color
                movb byte ptr gs:[bx], byte ptr Color
                add bx,140h
                inc di
                loop DIB2

                ifedo byte ptr Color, 15, ResetColor
                jmp IncColor

ResetColor:     mov byte ptr Color,0
IncColor:       inc byte ptr Color

		popall
                ret

DrawImaBorders ENDP

;-----------------------------------------------------------------------

FindLastSto	PROC NEAR
		pushall
		mov ax, word ptr NameOfIms-2
                shr ax,2
                mov word ptr LastSto,ax
                popall
                ret

FindLastSto	ENDP

;--------------------------------------------------------------------

;ScriptNoTxt	db "Script Entry  :0000",0
;ImaNameTxt	db 81 DUP (0)
;DysplayAttTxt	db "Dysplay Att.  :0",0
;ObjStatTxt	db "Obj. Status   :00",0

DrawTexts PROC NEAR

		HexFrameExtender byte ptr ScrX, offset Coordinates + 2
		HexFrameExtender byte ptr ScrY, offset Coordinates + 8
                HexFrameExtender byte ptr Mx, offset Coordinates + 12+3
                HexFrameExtender byte ptr My, offset Coordinates + 17+5

                HexFrameExtender byte ptr DysplayAtt,offset DysplayAttTxt+15
                HexFrameExtender byte ptr ObjStat, offset ObjStatTxt+15

		mov ax, word ptr ScrPtr
                sub ax, offset ScrDefs
                shr ax,3
                mov word ptr EntryNo, ax

                HexFrameExtender byte ptr EntryNo+1,offset ScriptNoTxt +15
                HexFrameExtender byte ptr EntryNo, offset ScriptNoTxt+17
		HexFrameExtender byte ptr Unused, offset Unused1Txt+10
                HexFrameExtender byte ptr Unused+1, offset Unused2Txt+10

                mov word ptr NamePtr, offset ImsNames
                mov cx,word ptr ImaNo
                ifedo cx,0,FoundNamesTxt
TryAgain:       skipchar LIBRAIRY, word ptr NamePtr, 13
                loop TryAgain

FoundNamesTxt:
                copymem DATA,offset ImaNameTxt,LIBRAIRY,word ptr NamePtr,75

		WriteToScreen 0,19,offset Coordinates
		WriteToScreen 0,21,offset ScriptNotxt
		WriteToScreen80 0,22,offset ImaNameTxt
		WriteToScreen 0,23,offset DysplayAttTxt
		WriteToScreen 0,24,offset ObjStatTxt
                WriteToScreen 20,23,offset Unused1Txt
                WriteToScreen 20,24,offset Unused2Txt

                ret

DrawTexts ENDP

;--------------------------------------------------------------------------


;************************************************************************
; 		STATICS OBJS MANAGER FOR ROOM EDITOR V1.0
;************************************************************************

StoManager	PROC NEAR


                push word ptr ScrX		; SaveX&Y on stack

                mov ax, word ptr CurrentSto
                shl ax,2
                add ax, offset StoDefs
                mov word ptr StoPtr, ax

UpdateSto:      ;eraseseg 0a000h

		;set gs,0a000h
                set gs,SCREEN
                mov cx,65536/4
                mov eax,00010001h
		nul di
Clr:            mov gs:[di],eax
                add di,4
                loop Clr

                call FillStoSection

 		movw word ptr CurrentIma, word ptr _ImaNo
                mov word ptr ScrX,0
		call DrawStoTexts


                call ImaSizeFiller
                copyseg 0a000h,SCREEN
		call DrawIma


XXZ:		call DrawImaBorders
    		call Getax

                ifedo al,"c",Bye
                ifedo al,"C",Bye

                ifedo al,"n",NxSto
                ifedo al,"N",NxSto
                ifedo al,"b",BkSto
                ifedo al,"B",BkSto

                ifedo al,13,SaveSto

                jmp XXZ

;---------------------------------------------------------------------
;---------------------------------------------------------------------

NxSto:		cmpw word ptr CurrentSto, word ptr LastSto
		je XXZ

                inc CurrentSto
                add StoPtr,4
                jmp UpdateSto

;------------------------------------------------------------------------

BkSto:		ifedo word ptr CurrentSto,0, XXZ

		dec CurrentSto
                Sub StoPtr,4
                jmp UpdateSto

;------------------------------------------------------------------------

Bye:            pop word ptr ScrX
                ret

; Information put-in byte AUTO-FILL	(SCRIPT INFO)
;DysplayAtt	db 0
;ObjStat	db 0
;Unused		dw 0
;ImaNo		dw 0
;ObjX		db 2
;ObjY		db 2

; Information put-in for STO DEFS
;_DysplayAtt	db 0
;_ObjStat	db 0
;_ImaNo		dw 0

;------------------------------------------------------------------------

SaveSto:        set ds, DATA
		movb byte ptr DysplayAtt, byte ptr _DysplayAtt
		movb byte ptr ObjStat, byte ptr _ObjStat
                movw word ptr ImaNo, word ptr _ImaNo
                pop word ptr ScrX
                ret

;------------------------------------------------------------------------

StoManager	ENDP


FillStoSection PROC NEAR

; Information put-in for STO DEFS
;_DysplayAtt	db 0
;_ObjStat	db 0
;_ImaNo		dw 0

		CopyMem DATA,offset _DysplayAtt,LIBRAIRY,word ptr StoPtr,4
		ret

FillStoSection ENDP

DrawStoTexts	PROC NEAR

;_ObjNoTxt	db "Obj No.       :0000",0
;_ImaNameTxt	db 81 DUP (0)
;_DysplayAttTxt	db "Dysplay Att.  :00",0
;_ObjStatTxt	db "Obj. Status   :00",0

		HexFrameExtender byte ptr CurrentSto+1, offset _ObjNoTxt+15
                HexFrameExtender byte ptr CurrentSto, offset _ObjNoTxt+17

              HexFrameExtender byte ptr _DysplayAtt,offset _DysplayAttTxt+15
              	HexFrameExtender byte ptr _ObjStat, offset _ObjStatTxt+15

		mov word ptr NamePtr, offset ImsNames
                mov cx,word ptr CurrentIma
                ifedo cx,0,FoundNamesTxt_
TryAgain_:      skipchar LIBRAIRY, word ptr NamePtr, 13
                loop TryAgain_

FoundNamesTxt_:
                copymem DATA,offset _ImaNameTxt,LIBRAIRY,word ptr NamePtr,75

		WriteToScreen 0,21,offset _ObjNoTxt
		WriteToScreen80 0,22,offset _ImaNameTxt
		WriteToScreen 0,23,offset _DysplayAttTxt
		WriteToScreen 0,24,offset _ObjStatTxt

DrawStoTexts	ENDP

;--------------------------------------------------------------------

FindLastIma	PROC NEAR

		set es,LIBRAIRY

		xor ax,ax
                mov si,ax

LookFLI:        ifedo word ptr es:[si],0, FoundLastIma
                mov si,es:[si]
                inc ax
                jmp LookFLI

FoundLastIma:	mov word ptr LastIma, ax
          	ret

FindLastIma	ENDP

;------------------------------------------------------------------------

DrawScreen_ PROC NEAR

		pushall

                eraseseg SCREEN
		call TrialEntries
                call TinyScriptCompiler
                ;CopySeg 0a000h,SCREEN

                popall
                ret


DrawScreen_ ENDP

;-------------------------------------------------------------------------

TrialEntries	PROC NEAR

		;pushall

                set es,LIBRAIRY

                mov dx, word ptr ScrEnd
                sub dx,offset ScrDefs
                shr dx,3

                mov si,offset ScrDefs
                mov di,offset ScrTemp

                mov bp,dx
                ifedo bp,0,EndOfScr
                ;dec bp
                ;ifedo bp,0,EndOfScr

                mov dx,word ptr MX

ChkNxEntry:
                mov ax,es:[si+6]		; AL=ObjX, AH=ObjY

                xor bx,bx
                mov cx,word ptr es:[si+4]	; CurrentIma
                jcxz FoundImaPtr

ChkNxIma:       mov bx,es:[bx]
                loop ChkNxIma

FoundImaPtr:	mov cl,es:[bx+2]		; CL=Obj Lenght
		mov ch,es:[bx+4]		; CH=Obj height

		mov bx,dx			; BL= MX; BH=MY

		; OX+OL >= MX
		add al,cl
                cmp al,bl
                jb ItIsOver

                ; OX <= MX+40
                add bl,40
		sub al,cl
                cmp al,bl
                ja ItIsOver

                ; OY+OH >= MY
                add ah,ch
                cmp ah,bh
                jb ItIsOver

                ; OY <= MY+40
		add bh,25
                sub ah,ch
                cmp ah,bh
                ja ItIsOver

		mov eax,es:[si]
                mov es:[di],eax
                mov eax,es:[si+4]
                mov es:[di+4],eax

		add di,8

ItIsOver:       add si,8
		mov cx,bp
		dec bp
                loop ChkNxEntry

EndOfScr:       mov word ptr es:[di],-1

                ;popall
                ret

TrialEntries 	ENDP

;----------------------------------------------------------------------


TinyScriptCompiler PROC NEAR

		set es, Librairy
                set gs, SCREEN
                ;set fs, Statics

                mov si,offset ScrTemp
                xor di,di


		; ********************************************
                ; Vérification des objs de type background...
                ; ********************************************

ChkNxTempE:     mov ax,word ptr es:[si]
                cmp ax,-1
                je Part2

                or al,al
                jne NotInBackGround

                call ScriptObj

NotInBackGround:
		add si,8
                jmp ChkNxTempE


Part2:          mov si,offset ScrTemp
XXX:     	mov ax,word ptr es:[si]
                cmp ax,-1
                je BKFini

                cmp al,1
                jne NotInFoward

                call ScriptObj

NotInFoward:
		add si,8
                jmp XXX

                ; **********************************************
                ; Ajoute les définition Stat au script
                ; d'affichage.
		; **********************************************

ScriptObj:
                xor bx,bx
                mov cx, word ptr es:[si+4]	; current IMA

                jcxz TrouveImaPtr

ChercheImaPtr:  mov bx,word ptr es:[bx]
                loop ChercheImaPtr

TrouveImaPtr:   set hx, word ptr es:[bx+4]
		set lx, word ptr es:[bx+2]

                mov dx, word ptr es:[si+6]

                add bx, 6

SC2:						; ** BEGIN 2
                mov cx,lx			; ** BEGIN 1

SC1:


;--------------------------------------------------------------------

                mov ax, es:[bx]			; FONT
                or ax,ax
                je BlankIma

                push dx

                sub dl,byte ptr MX
                cmp dl,40
                jae NotOnScreen_

                sub dh,byte ptr MY
		cmp dh,25
                jae NotOnScreen_

                push bx

                mov bp,FONT
IsInSeg_:       cmp ax,1024
                jb InThisSeg

                sub ax,1024
		add bp,65536/16
                jmp IsInSeg_

InThisSeg:	shl ax,6
                mov bx,ax
                mov fs,bp

                mov ax,dx
             	xor dh,dh
                shl dx,3
                mov di,dx

                mov al,0ah
                mul ah
                shl ax,8
                add di,ax

                push cx

                mov dx,8
NxLine:         mov cx,8

NxPix:          mov al,fs:[bx]
                or al,al
                je BooNUL

                mov gs:[di],al

BooNUL:		inc bx
		inc di
                loop NxPix

                add di,140h-8
                mov cx,dx
                dec dx
                loop NxLine

                pop cx

;-------------------------------------------------------------------

		pop bx
NotOnScreen_:	pop dx

BlankIma:       add bx,2
                inc dl
                loop SC1            		; ** END 1

		mov dl,byte ptr es:[si+6]
                inc dh
                mov cx,hx
                dec hx
                eloop SC2                        ; ** END 2

		ret

                ; ********************************************
                ; C'est fini.. ha! ha! ha! ...
                ; ********************************************

BKFini:         ;mov word ptr fs:[di],-1

		ret


TinyScriptCompiler ENDP

;----------------------------------------------------------------------

MainProgram PROC NEAR

		set ds,DATA
                eraseseg LIBRAIRY

		call DysplayMenu
                call AskOption
                call VideoSwitch
		EmulateStaticsMSQ DATA, offset Letters, offset ASCII_TABLE
                call InitScrManager
                call FindLastSto
                call FindLastIma
       		call ScrManager

                LeaveProgram 0

;-------------------------------------------------------------------------
MainProgram    ENDP                           ; Fin de la procedure
CODE ENDS                                ; Fin du programme
END     MainProgram                           ; Point d'entree
;-------------------------------------------------------------------------

