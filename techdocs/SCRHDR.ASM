;----------------------------------------------------------------
;       Script Header Utility V1.0
;       by Francois Blanchette
;----------------------------------------------------------------

include c:\Masm61\listing\SsfsMac.INC
include c:\MASM61\LISTING\IOSYSTEM.INC

; Enables all externals definitions...
UseRepV2	; 94REPV2.ASM
UseSTATV2	; 94STATV2.ASM

;-----------------------------------------------------------------

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

;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------

;----------------------------------------------------------------
DATA      SEGMENT PUBLIC 'DATA'
COPYRIGHT      	db "Script Header UTILITY V1.1 "
	       	db "(C) 1994: FRANCOIS BLANCHETTE"
GIVENAME       	db 13,10,"Enter the name of .SCR file you want to be"
		db " maped. ",13,10,13,10
                db "For exemple:",13,10
                db "SCRHDR intro",13,10,13,10
                db "$"

PSP 	       db 256 DUP (0)

align 2
ScrLen		dw 0
StoLen		dw 0
FileNamePtr	dw 0
ImaNo		dw 0
NamePtr		dw 0

StoParent	db 16 DUP (0)
ImsParent     	db 16 DUP (0)

_SCR		db ".SCR",0,"$"
_MAP		db "RPT",0,"$"


FileLinked	db 13,10,"CHILD FILE:"
ChildName	db 40 DUP (32)
		db 13,10,13,10
ChildName_	db 0

ImsParentTxt    db 13,10
		db "List of .IMA contained in the IMS mother file:"
		db 13,10,13,10,"No   Description",13,10
ImsParentTxt_   db 0

StoParentTxt	db 13,10,13,10
		db "List of Statics Objs contained in the .STO file:"
                db 13,10,13,10
                db "Legend:",13,10
                db "DA= Dysplay Attributs (0=background, 1=fowardground)",13,10
                db "ID= Objet ID number",13,10
                db 13,10,"No   Description                             "
                db " DA ID",13,10
StoParentTxt_	db 0

ScrParentTxt	db 13,10,13,10
		db "List of Script entries in .SCR CHILD file:"
                db 13,10,13,10
                db "Legend:",13,10
                db "DA= Dysplay attributs (0=Background, 1=fowardground)",13,10
                db "ID= Obj. ID number",13,10
                db "U1= Unused #1",13,10
                db "U2= Unused #2",13,10
                db "X = Xpos",13,10
                db "Y = YPos",13,10
                db 13,10,"No   Description                             "
                db " DA ID U1 U2 X_ Y_ ",13,10
ScrParentTxt_	db 0

ImaNoTxt	db "0000 "
ImaName		db 60 DUP (0)
		db 13,10

StoNoTxt	db "0000 "
ImaName2	db 41 DUP (32)
DA		db "00 "
ID		db "00 ",13,10
StoEnd_		db 0

ScrNoTxt	db "0000 "
ImaName3	db 41 DUP (32)
DA_		db "00 "
ID_		db "00 "
U1		db "00 "
U2 		db "00 "
X_		db "00 "
Y_		db "00 ",13,10
ScrEnd_		db 0
DATA   ENDS

;----------------------------------------------------------------
LenImsParentTxt EQU offset ImsParentTxt_ - offset ImsParentTxt
LenStoParentTxt	EQU offset StoParentTxt_ - offset StoParentTxt
LenScrParentTxt	EQU offset ScrParentTxt_ - offset ScrParentTxt
LenImaNoTxt 	EQU 5
StoTxtLen	EQU offset StoEnd_ - offset StoNoTxt
ScrTxtLen	EQU offset ScrEnd_ - offset ScrNoTxt
ChildLen	EQU offset ChildName_- offset FileLinked
;----------------------------------------------------------------

LIBRAIRY SEGMENT 'LIBRAIRY' PUBLIC
LIBRAIRY ENDS

FONT SEGMENT 'FONT' PUBLIC
FONT ENDS

STATICS SEGMENT 'STATICS' PUBLIC
STATICS ENDS

SCREEN SEGMENT 'SCREEN' PUBLIC
SCREEN ENDS

;----------------------------------------------------------------
CODE SEGMENT READONLY PUBLIC 'CODE'
VLAMITS  PROC NEAR
;----------------------------------------------------------------
.386

		nul bh
		mov bl,es:[80h]
		cmp bl,0
		je GIVE_CM_LINE

		mov cl,bl
		mov ch,0
		inc cx

		mov dx,DATA
		mov ds,dx

		mov si,80h
		mov di,offset PSP

XTRSN:		mov al,es:[si]
                cmp al,"."
                je DotFound
		mov [di],al

		inc si
		inc di
		loop XTRSN

DotFound:

                mov si,offset _SCR
                call EXT

		jmp PREPARE

GIVE_CM_LINE:   mov dx,DATA
		mov ds,dx
		mov dx,offset GIVENAME
		mov ah,9
		int 21h
                leaveprogram -1
PREPARE:
                sub sp,2
                mov bp,sp

                ScrFile	EQU word ptr [bp]
                StoFile EQU word ptr [bp]
                MapFile EQU word ptr [bp]

                set ds,DATA

                HOpenForRead offset PSP+2, ScrFile
		HReadFile DATA,offset ScrLen, 2, ScrFile
                HReadFile DATA, offset StoParent, 16, ScrFile
                HReadFile LIBRAIRY, offset ScrDefs, word ptr ScrLen, ScrFile
                HClose ScrFile

		HOpenForRead offset StoParent, StoFile
                HReadFile DATA, offset StoLen, 2, StoFile
                HReadFile DATA, offset ImsParent, 16, StoFile
                HReadFile LIBRAIRY, offset Stodefs, word ptr StoLen, StoFile
                HClose StoFile

		mov dx, offset ImsParent
                call LoadIms

                set ds,DATA

                mov di,offset ChildName
                mov si,offset PSP+2

CopyChildName:  mov al,[si]
                cmp al,0
                je EndOfName

                mov [di],al
                inc si
                inc di
                loop CopyChildName
EndOfName:


                ; ADD A .MAP EXTENSION
		mov word ptr FilenamePtr, offset PSP+2
                SkipChar DATA, FileNamePtr, "."
                mov di, word ptr FileNamePtr
                mov si, offset _MAP
                call EXT

                ; Creat .MAP file
		HCreat offset PSP+2,MapFile
                HWrite DATA, offset FileLinked, ChildLen, MapFile

		;********************************************************
                ; Cette section offre une liste complète de toutes
                ; les images contenues dans le fichier .IMS parent.
                ;*********************************************************

		HWrite DATA, offset ImsParentTxt, LenImsParentTxt, MapFile

                ; Write Name of .IMA into MAP

                set es,LIBRAIRY

                mov word ptr NamePtr,offset ImsNames

NxImaName1:     mov si,word ptr NamePtr
                cmp byte ptr es:[si],0
                je ImsOver

		HexFrameExtender byte ptr ImaNo+1, offset ImaNoTxt
                HexFrameExtender byte ptr ImaNo, offset ImaNoTxt+2
                inc word ptr ImaNo

                FillMem DATA,offset ImaName,60,32

                mov cx,60
                mov di,offset ImaName
CopyName1:      mov al,es:[si]
                cmp al,13
                je EndName1

                mov [di],al
		inc si
                inc di
		loop CopyName1

EndName1:       HWrite DATA, offset ImaNoTxt, 62+5, MapFile

		SkipChar LIBRAIRY, word ptr NamePtr, 13
		mov si,word ptr NamePtr
                cmp byte ptr es:[si],10
                jne NxImaName1

                inc word ptr NamePtr
                jmp NxImaName1

ImsOver:

		;****************************************************
                ; Cette section effectue l'autopsie du fichier .STO
                ; parent du fichier .SCR fils.
                ;****************************************************

                HWrite DATA, offset STOParentTxt, LenSTOParentTxt, MapFile
		mov word ptr ImaNo,0

                mov ax,word ptr StoLen
                ifedo ax,0, StoOver
		shr ax,2

                mov dx,ax

                mov si,offset StoDefs

Again2:         mov cx, word ptr es:[si+2]
                call GetNamePtr

                FillMem DATA, offset ImaName2, 40, 32

                mov cx,40
		mov di,offset ImaName2
CopyName2:	mov al,es:[bx]
		cmp al,13
                je EndName2

                mov [di], al
                inc di
                inc bx
		loop CopyName2

EndName2:       HexFrameExtender byte ptr ImaNo+1, offset StoNoTxt
                HexFrameExtender byte ptr ImaNo, offset StoNoTxt+2
                inc word ptr ImaNo

                HexFrameExtender byte ptr es:[si], offset DA
                HexFrameExtender byte ptr es:[si+1], offset ID

		HWrite DATA, offset StoNoTxt, StoTxtLen, MapFile

                add si,4
                mov cx,dx
                dec dx
                eloop Again2

StoOver:

		;*****************************************************
                ; Let make the .SCR file scream! Yeah!
                ;*****************************************************

;ScrNoTxt	db "0000 "
;ImaName3	db 41 DUP (32)
;DA_		db "00 "
;ID_		db "00 "
;U1		db "00 "
;U2 		db "00 "
;X_		db "00 "
;Y_		db "00 ",13,10

                HWrite DATA, offset ScrParentTxt, LenScrParentTxt, MapFile
		mov word ptr ImaNo,0

                mov ax,word ptr ScrLen
                ifedo ax,0, ScrOver
		shr ax,3

                mov dx,ax

                mov si,offset ScrDefs

Again3:         mov cx, word ptr es:[si+4]
                call GetNamePtr

                FillMem DATA, offset ImaName3, 40, 32

                mov cx,40
		mov di,offset ImaName3
CopyName3:	mov al,es:[bx]
		cmp al,13
                je EndName3

                mov [di], al
                inc di
                inc bx
		loop CopyName3

EndName3:       HexFrameExtender byte ptr ImaNo+1, offset ScrNoTxt
                HexFrameExtender byte ptr ImaNo, offset ScrNoTxt+2
                inc word ptr ImaNo

                HexFrameExtender byte ptr es:[si], offset DA_
                HexFrameExtender byte ptr es:[si+1], offset ID_

                HexFrameExtender byte ptr es:[si+2], offset U1
                HexFrameExtender byte ptr es:[si+3], offset U2

                HexFrameExtender byte ptr es:[si+6], offset X_
                HexFrameExtender byte ptr es:[si+7], offset Y_

		HWrite DATA, offset ScrNoTxt, ScrTxtLen, MapFile

                add si,8
                mov cx,dx
                dec dx
                eloop Again3

SCrOver:

                ;******************************************************
                ; BYE NOW EVERYTHING IS OVER...
                ;******************************************************

                HClose MapFile
		LeaveProgram 0

;-------------------------------------------------------------------

GetNamePtr:     mov bx,offset ImsNames
                mov word ptr NamePtr, bx
		jcxz FoundnamePtr
LeapThrought:
		SkipChar LIBRAIRY, word ptr NamePtr, 13
                mov bx,word ptr NamePtr
                cmp byte ptr es:[bx],10
                jne Not10
                inc word ptr NamePtr

Not10:
                loop LeapThrought

FoundNamePtr:   mov bx, word ptr NamePtr
		ret

; -----------------------FIN DU PROGRAMME-----------------------
VLAMITS    ENDP                           ; Fin de la procedure
CODE ENDS                                ; Fin du programme
END     VLAMITS                           ; Point d'entree
;---------------------------------------------------------------
