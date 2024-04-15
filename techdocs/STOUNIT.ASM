;----------------------------------------------------------------
;       STO unit
;       by Francois Blanchette
;----------------------------------------------------------------

; NOTE: REQUIERS 94REP
include c:\Masm61\listing\SsfsMac.INC
include c:\Masm61\listing\iosystem.INC

; Enables all externals definitions...
UseRep		; 94REP.ASM
UseNEOSYS	; 94NEOSYS.ASM
;UseSSFSLB	; 94SSFSLB.ASM  (that tried to improve the SSv1)
;UseSTATLB	; 94STATLB.ASM  (that ran the SSv1)

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

                set <gs>, 0a000h
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

                set <gs>, 0a000h
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

PUBLIC CONVENSIONS
PUBLIC PATH
PUBLIC ROOM_NAMES

;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------

;----------------------------------------------------------------
DATA      SEGMENT PUBLIC 'DATA'
Copyright	db "Statics Objs Librairies (C) 1995 Francois Blanchette"
Copyright_	db 0

StoEditMenu_    db 13,10
		db "Statics Objs Editor V1.0",13,10
                db "by Francois Blanchette.",13,10,13,10
                db "Please select an option:",13,10,13,10
                db "C. Creat a new .STO",13,10
                db "L. Load an existing .STO",13,10,13,10,"$"

StoLoadTxt	db "Name of existing .STO:$"
StoCreatTxt	db "Name of new .STO file:$"


ObjNoTxt	db "OBJ NO   : "
		db 4 DUP (30h)
                db 20 DUP (32)
                db "B/N",0

                db 0
ImaNameTxt	db ".IMA NAME: "
		db 80 DUP (32)
                db 20 DUP (32)
                db "Z / X ",0

ObjIdTxt	db "OBJ ID NO: 00"
		db 20+2 DUP (32)
                db "A/S",0

ObjAttTxt	db "DYSP. ATT:  ",0

ImsParentTxt	db 13,10,"Name .Ims parent file:$"
StoNameCmp	db 0,0
StoName		db 16 DUP (0)
ImsNameCmp	db 0,0
ImsParent       db 16 DUP (0)

STO		db ".STO",0,"$"
IMS		db ".IMS",0,"$"

PATH           	db 0
ROOM_NAMES	db 0

align 2
StoFileCode	dw 0
ImsFileCode	dw 0

; STO-HEADER
StoHeader       dw 0
ImsName		db 16 DUP (0)
StoSubHeader	dw 0

; IMS-HEADER
NbFonts		dw 0
StatLenght	dw 0

; Letters will be copied from the BIOS matrix to this wonderful buffer.

ASCII_TABLE     db " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"
		db "#$%&*().!,/?:;+-{}[]\|`~<>1234567890",0,-1

align 4
LETTERS		db (offset Letters - offset ASCII_TABLE)*64 DUP (0)
StoErrorTxt	db "Warning: Error occured! R)etry A)bort?",13,10,"$"
ResetTxt        db "Do you want to reset program (Y/N)?",0,"$"

align 2
CurrentSto	dw 0
LastSto		dw 0

CurrentIma	dw 0
LastIma		dw 0
NamePtr		dw 0
StrSize		dw 0
IdNo		dw 0	; Used only as byte
DysplayAtt	dw 0    ; Used only as byte

DATA   ENDS

FONT SEGMENT 'FONT' PUBLIC
FONT ENDS

FONT2 SEGMENT 'FONT2' PUBLIC
FONT2 ENDS

FONT3 SEGMENT 'FONT3' PUBLIC
FONT3 ENDS

FONT4 SEGMENT 'FONT4' PUBLIC
FONT4 ENDS

LIBRAIRY SEGMENT 'LIBRAIRY' PUBLIC
LIBRAIRY ENDS

;----------------------------------------------------------------

StoFile		EQU word ptr StoFileCode
LenghtCopyright EQU offset Copyright_ - offset Copyright
SizeOfFieldName	EQU 11
DelKey		EQU 83

;----------------------------------------------------------------
CODE SEGMENT READONLY PUBLIC 'CODE'

.386


;--------------------------------------------------------------------

InitVideo PROC NEAR

		mov al,3
                nul ah
                int 10h
                ret

InitVideo ENDP

;--------------------------------------------------------------------

RestoreOldMode PROC NEAR

		mov al,byte ptr Old_Video_Mode
                nul ah
                int 10h
                ret

RestoreOldMode ENDP


;------------------------------------------------------------------

StoEditMenu PROC NEAR
                pushall
                clearscreen
                locate 0,0
		Print offset StoEditMenu_

KeyEditMenu:	call Getax
                cmp al,"L"
                jsem LoadOptionSM, LeaveEditMenu

                cmp al,"l"
                jsem LoadOptionSM, LeaveEditMenu

                cmp al,"C"
                jsem CreatOptionSM, LeaveEditMenu

                cmp al,"c"
                jsem CreatOptionSM, LeaveEditMenu

		jmp KeyEditMenu

LeaveEditMenu:	popall
		ret

LoadOptionSM:	print offset StoLoadTxt
		input offset StoNameCmp, 8
		gosub AddExt_STO
                ret

CreatOptionSM:	print offset StoCreatTxt
		input offset StoNameCmp, 8
		gosub AddExt_STO

                ; Creat ????.STO as output file
                Hcreat offset StoName, StoFile
                Hwrite DATA, offset StoHeader, 2, StoFile

		print offset ImsParentTxt
                input offset ImsNameCmp, 8
                gosub ADDExt_IMS

		copymem DATA, offset ImsName, DATA, offset ImsParent, 16

                Hwrite DATA, offset ImsName, 16, StoFile
                Hwrite DATA, offset StoSubHeader, 2, StoFile
                Hwrite DATA, offset Copyright, LenghtCopyright, StoFile
                Hclose StoFile
                ret

AddExt_STO:     SetSeg <DS>,DATA

		mov bl,byte ptr StoNameCmp+1
		nul bh

                mov di,offset StoName
                add di,bx
                mov si,offset STO
                gosub Ext
                ret

AddExt_IMS:	SetSeg <DS>, DATA

		mov bl,byte ptr ImsNameCmp+1
                nul bh

                mov di,offset ImsParent
                add di,bx
                mov si,offset IMS
                gosub Ext
                ret

StoEditMenu ENDP	; (* Fin de StoEditMenu *)


LoadStoFile PROC NEAR

                ; Load XXXX.STO
                HOpenForRead offset StoName, StoFile
                HReadFile DATA, offset StoHeader, 18, StoFile
                HReadFile LIBRAIRY, offset StoDefs, word ptr StoHeader, StoFile
		;HReadFile DATA, offset StoSubHeader, 2, StoFile
                ;HReadFile LIBRAIRY, offset StoNames, word ptr StoSubHeader, StoFile
                HClose StoFile
                ret

LoadStoFile ENDP	; (* Fin de LoadStoFile *)

LoadImsParent PROC NEAR

		; Load XXXX.IMS

		HLoadIms offset StoHeader+2
                ret

LoadImsParent	ENDP;	(* Fin de LoadImsParent *)


Initialize PROC NEAR

                EraseSeg Librairy
		nul word ptr StoHeader
		ret

Initialize ENDP		; (* Fin de Initialize *)

InitStoEditor  PROC NEAR

		gosub VideoSwitch
		EmulateStaticsMSQ DATA, offset Letters, offset ASCII_TABLE
		ret

InitStoEditor ENDP    	; (* Fin de InitStoEditor *)


CONVENSIONS::
		push dx
		mov dx,DATA
		mov ds,dx
		pop dx
		ret

; ********************************************************************
; This routine will handler error with loading the .STO file & his
; parent .IMS file.
; ********************************************************************

StoErrorsHandler PROC NEAR

		mov sp,3f0h
                print offset StoErrorTxt

ScanKeySEH:     call Getax
                cmp al,"r"
                je SEHRetry
                cmp al,"R"
                je SEHRetry

                cmp al,"a"
                je SEHAbort
                cmp al,"A"
                je SEHAbort

                jne ScanKeySEH

SEHRetry:	jmp MainProgram
SEHAbort:	jmp EHandler

StoErrorsHandler ENDP; (* Fin de StoErrorsHandler *)

; ********************************************************************
; Change the default the errors handler with the StoErrorsHandler.
; ********************************************************************

SetStoErrorsHandler PROC NEAR

		HSetHandler StoErrorsHandler
                ret

SetStoErrorsHandler ENDP ; (* Fin de SetStoErrorsHandler *)

;----------------------------------------------------------------------

InitStoEditManager PROC NEAR

		sub sp,4
		mov bp,sp

		HOpenForRead offset StoName, word ptr [bp+2]
                HReadFile STACK, bp, 2, word ptr [bp+2]
                HClose word ptr [bp+2]

                setseg <ds>, DATA
		mov ax, [bp]
                shr ax,2

                add sp,4


                ; modification 18/12/94
                mov word ptr CurrentSto,ax
                mov word ptr LastSto,ax

                ret

InitStoEditManager ENDP ; (* Fin de InitStoEditManager *)

;-----------------------------------------------------------------------

UpdateStoScreen PROC NEAR

                call AjustTxtStrings

		call DrawIma
                call DrawTexts
                ret

UpdateStoScreen ENDP; (* Fin de UpDateStoScreen *)

;-----------------------------------------------------------------------

DrawTexts PROC NEAR

		WriteToScreen 1,17, offset ObjNoTxt
                WriteToScreen80 1,18, offset ImaNameTxt
		WriteToScreen 1,20, offset ObjIdTxt
                ;WriteToScreen 1,21, offset ObjStatTxt
                ;WriteToScreen 1,22, offset ObjPropsTxt
                WriteToScreen 1,23, offset ObjAttTxt

                ret

DrawTexts ENDP

;-----------------------------------------------------------------------

AjustTxtStrings	PROC NEAR

                ; /////////////\\\\\\\\\\
		; ||||| IMA name   ||||||
                ; ///////////////////////

                pushall
                set <es>, Librairy
                set <ds>, Data

                mov word ptr NamePtr, offset ImsNames
                mov ax, word ptr CurrentIma
VerifAx:        ifedo ax,0,FoundImaName

                skipchar Librairy, word ptr NamePtr, 13
                dec ax
                jmp VerifAx

FoundImaName:
		erasemem DATA,offset ImaNameTxt+11, 45

	copymem DATA,offset ImaNameTxt+11,Librairy,word ptr NamePtr,40

		ifedo byte ptr DysplayAtt,1, FGround
                mov byte ptr ObjAttTxt+11, "B"
        	jmp NotFGround
FGround:	mov byte ptr ObjAttTxt+11, "F"

NotFGround:

                ; ///////////////////////
                ; ||||| Obj ID Txt   ||||
                ; \\\\\\\\\\\\\\\\\\\\\\\

                ;HexFrameExtender byte ptr CurrentIma+1, offset ObjNoTxt+11
                ;HexFrameExtender byte ptr CurrentIma,  offset ObjNoTxt +13
		HexFrameExtender byte ptr IdNo, offset ObjIdTxt+11
                HexFrameExtender byte ptr CurrentSto+1, offset ObjNoTxt+11
                HexFrameExtender byte ptr CurrentSto, offset ObjNoTxt+13

                popall
                ret

AjustTxtStrings ENDP; (* Fin de AjustTxtStrings *)


;-----------------------------------------------------------------------

FindCurrentIma   PROC NEAR

		pushall
		set <es>, LIBRAIRY

                mov si, word ptr CurrentSto
                shl si,2
                add si,offset StoDefs

                movw word ptr CurrentIma, es:[si+2]	; CurrentIma!

		popall

FindCurrentIma ENDP

;------------------------------------------------------------------------


FindLastIma	PROC NEAR

		pushall

                set <ds>, DATA
                set <es>, LIBRAIRY
		nul si

                mov ax,0
TestAgain:      mov si,es:[si]
                cmp si,0
                je LastFound
                inc ax
                jmp TestAgain

LastFound:	mov word ptr LastIma, ax
                dec word ptr LastIma
                popall
                ret

FindLastIma	ENDP

;-------------------------------------------------------------------


DrawIma PROC NEAR

		; Initialise segments
		set <DS>, DATA
                set <es>, LIBRAIRY
                set <gs>, 0a000h

                mov cx, word ptr CurrentIma
                ;mov cx, es:[si+4]
                cmp cx,0
                je FirstIma

                nul si
NextIma:        mov si,es:[si]
                loop NextIma
                jmp NotFirstIma

FirstIma:       nul si
NotFirstIma:

                mov di,0

                movw fx, word ptr es:[si+2]	; fx <- Largeur
                movw gx, word ptr es:[si+4]	; gx <- Hauteur
                add si,6

DrawLine2:      push di
		push fx

DrawLine:       push di

		mov bx,es:[si]
                mov dx,FONT

ChkA:           cmp bx,1024
                jb InSeg
                sub bx,1024
                add dx,65536/16
		jmp ChkA

InSeg:          set <fs>,dx
                shl bx,6			; FontPtr
                add si,2

                mov cx, 8
DrawFont:       mov eax, fs:[bx]
                mov gs:[di], eax
                mov eax, fs:[bx+4]
                mov gs:[di+4], eax
                add bx,8
                add di,140h
                loop DrawFont

                pop di
                add di,8
		mov cx,fx
                dec fx
                loop DrawLine

                pop fx
                pop di
                add di,0a00h
                mov cx,gx
                dec gx
                loop DrawLine2

		ret

DrawIma ENDP; (Fin de DrawIma*)


;-----------------------------------------------------------------------

StoEditManager	PROC NEAR
		set <es>, LIBRAIRY
		set <ds>, DATA

                mov si, word ptr CurrentSto
                shl si,2
                add si,offset StoDefs

                ; Restore Dysp. Att. 0
                movb byte ptr dysplayAtt, byte ptr es:[si]
                ; Restore IdNo
                movb byte ptr IdNo, byte ptr es:[si+1]

                ; Restore CurrentIma 4
                movw word ptr CurrentIma, word ptr es:[si+2]

Update:		EraseSeg 0a000h

		call UpdateStoScreen

XX:             call Getax

                mov bp,-1
                ifedo al,"z",DecIma
                ifedo al,"x",IncIma
                ifedo al,"Z",DecIma
                ifedo al,"X",IncIma

                ifedo al,",",DecIdNo
                ifedo al,".",IncIdNo
                ifedo al,"<",DecIdNo
                ifedo al,">",IncIdNo

                ifedo al,13,StoreSto
                ifedo al,"n",IncSto
                ifedo al,"b",DecSto
                ifedo al,"N",IncSto
                ifedo al,"B",DecSto

                ifedo al,"q", Ret_
                ifedo al,"Q", Ret_

                ifsedo al,"=", SaveStoFile
                ifsedo al,"+", SaveStoFile

                ifedo al," ",ChngDysplayAtt
                ifedo al," ",ChngDysplayATt

                ifedo ah,DelKey, DelSto

                ifsedo al,9, IsResetProg
                ifedo bp,0, ret_

                jmp XX
Ret_:           ret

;------------------------------------------------------------------------

DelSto:		cmpw word ptr CurrentSto, word ptr LastSto
                je XX

                mov cx,word ptr LastSto
                sub cx,word ptr CurrentSto

                mov di,word ptr CurrentSto
                shl di,2
                add di,offset StoDefs

                mov si,di
                add si,4

                set es,LIBRAIRY

DoDelSto:       mov eax,es:[si]
                mov es:[di],eax

		add si,4
                add di,4
                loop DoDelSto

                dec word ptr LastSto

                jmp StoEditManager

;------------------------------------------------------------------------
IsResetProg:	locate 0,0
		print offset ResetTxt
ChkKeyB:        call Getax
                jnerr ChkKeyB
                ifedo al,"y", ResetYes
                ifedo al,"Y", ResetYes
                ifedo al,"n", ResetNo
                Ifedo al,"N", ResetNo
                jmp ChkKeyB

ResetYes:
                add sp,2
                popall
                nul bp
		ret

ResetNo:        EraseSeg 0a000h
		call UpdateStoScreen
		ret

                ; Change l'attribut de l'obj statique

ChngDysplayAtt: xor byte ptr DysplayAtt, 1
                jmp Update

IncSto:		cmpw word ptr CurrentSto, word ptr LastSto
		je XX
                inc word ptr CurrentSto
                jmp StoEditManager

DecSto:		ifedo word ptr CurrentSto,0,XX
		dec word ptr CurrentSto
                jmp StoEditManager

                ; Store the current Sto entry into the STO defs libs
                ; in current memory.

StoreSto:	mov di,word ptr CurrentSto
		shl di,2
                add di,offset StoDefs

                set <es>,LIBRAIRY

		; Save dysplay ATT  	; 0
                movb byte ptr es:[di], byte ptr DysplayAtt
                ; Save IdNo		; 1
                movb byte ptr es:[di+1], byte ptr IdNo

                ; Save Ima  ; 2,3
                movw word ptr es:[di+2], word ptr CurrentIma

                cmpw word ptr CurrentSto, word ptr LastSto
                jne NotLastSto
                inc word ptr LastSto
		inc word ptr CurrentSto
		jmp Update
NotLastSto:	jmp XX

		; Change the object's ID number

DecIdNo:	ifedo byte ptr IdNo,0,XX
		dec byte ptr IdNo
                call AjustTxtStrings
		;call DrawIma
                call DrawTexts
                jmp XX

IncIdNo:	ifedo byte ptr IdNo, 255,XX
		inc byte ptr IdNo
                call AjustTxtStrings
		;call DrawIma
                call DrawTexts
                ;call AjustTxtStrings
                jmp XX

                ; Change the objects's associated .IMA

DecIma:		ifedo word ptr CurrentIma, 0, XX
                dec word ptr CurrentIma
                jmp Update

IncIma:		cmpw word ptr CurrentIma, word ptr LastIma
		je XX
                inc word ptr CurrentIma
                jmp Update


StoEditManager ENDP ; (* Fin de StoEditManager *)

;-----------------------------------------------------------------------

SaveStoFile PROC NEAR

		sub sp,4
                mov bp,sp

		HCreat offset StoName, word ptr [bp+2]

                set <ds>,DATA
                mov ax, word ptr LastSto
                shl ax,2
                mov word ptr [bp],ax

                HWrite STACK, <bp>, 2, word ptr [bp+2]
                HWrite DATA,offset ImsName, 16, word ptr [bp+2]
                HWrite LIBRAIRY,offset StoDefs, word ptr [bp], word ptr [bp+2]
                HWrite DATA,offset Copyright,LenghtCopyright,word ptr [bp+2]
                HClose word ptr [bp+2]

                add sp,4
                ret

SaveStoFile	ENDP ; (* Fin de SaveStoFile *)

;-----------------------------------------------------------------------

TestStoParent	PROC NEAR

		call VideoSwitch

                set <ds>,DATA
                set <fs>,FONT
                set <gs>,0a000h

                nul si
                nul di

                mov bp,20

CopyF3:         push di
                mov dx, 40

CopyF2:         push di

                mov cx,8
CopyF:          movd gs:[di], fs:[si]
                movd gs:[di+4], fs:[si+4]
                add di,140h
                add si,8
                loop CopyF

		pop di

                add di,8
                mov cx,dx
                dec dx
                loop CopyF2

		pop di
                add di,0a00h

                set cx,bp
                dec bp
                loop CopyF3

XX2:		call Getax
		jnerr XX2
                ret

TestStoParent ENDP

;-----------------------------------------------------------------------

		; * * * * * * * * * * * * * * * * * * * * *
                ;  	    Programme principal
                ; * * * * * * * * * * * * * * * * * * * * *

MainProgram  PROC NEAR

		set <ds>,DATA
                set <gs>,0a000h

		gosub SetStoErrorsHandler
		gosub Initialize
                gosub StoEditMenu
                gosub LoadStoFile
                gosub LoadImsParent
                gosub InitStoEditor

                gosub FindCurrentIma
                gosub FindLastIma
                gosub InitStoEditManager
                gosub StoEditManager

                ifsedo bp,0, InitVideo
                ifedo bp,0, MainProgram

                gosub TestStoParent
                gosub RestoreOldMode

                LeaveProgram 0


MainProgram    ENDP	; (* Fin de MainProgram *)
CODE ENDS
END     MainProgram

;======================================================================

