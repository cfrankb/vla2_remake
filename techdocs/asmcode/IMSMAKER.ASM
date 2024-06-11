;----------------------------------------------------------------
;       Image Librairies Maker V1.0
;       by Francois Blanchette
;----------------------------------------------------------------

INCLUDE C:\Masm61\listing\SsfsMac.INC

; Enables all externals definitions...
UseRep		; 94REP.ASM
;UseSSFSLB	; 94SSFSLB.ASM
;UseSTATLB	; 94STATLB.ASM

;-------------------------------------------------------------------------
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

PUBLIC CONVENSIONS
PUBLIC PATH

;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------

FONT SEGMENT
DB 65535 DUP (0)
FONT ENDS

FONT2 SEGMENT
DB 65535 DUP (0)
FONT2 ENDS

FONT3 SEGMENT
DB 65535 DUP (0)
FONT3 ENDS

FONT4 SEGMENT
DB 65535 DUP (0)
FONT4 ENDS

LIBRAIRY SEGMENT
Images 	DB 65535 DUP (0)
LIBRAIRY ENDS

SizeOfIniBuffer	EQU 16384*4 -1
SizeOfMxkBuffer EQU 2048*2 + 16384
SizeOfDesBuffer EQU 8192

;----------------------------------------------------------------
DATA      SEGMENT PUBLIC 'DATA'
COPYRIGHT      	db "IMS MAKER V1.1 (C) 1995: FRANCOIS BLANCHETTE"
DATE	       	db " JAN 06 1995"
COPYRIGHT_     	db 0
PATH           	db 0

PSP	       	db 256 DUP (0)

align 2
ImaNo		dw 0
IniFileCode 	dw 0
IniPtr		dw offset IniBuffer

align 4
ImaNoTxt	db "0000 "

align 4
Cell		db 256 DUP (0)

align 2
MxkPtr		dw 0
MxkBuffer 	db SizeOfMxkBuffer DUP (0)
IniFileName	db 65 DUP (0)
;IniBuffer	db SizeOfIniBuffer DUP (0)
DesFileCode	dw 0
DesPtr		dw 0
DesSize		dw 0
DesBuffer	db SizeOfDesBuffer DUP (0)
DesName		db 16 DUP (0)

align 2
MapFileCode	dw 0
MxkFileCode	dw 0
		dw 0
MapName		db "IMS.MAP",0
		db 64 DUP (0)
MxkName		db "IMS.MXK",0

align 2
ImsFileCode	dw 0
_IMS		db ".IMS",0,"$"
_IMA		db ".IMA",0,"$"
_DES		db ".DES",0,"$"
_INI		db ".INI",0,"$"
_MAP		db ".MAP",0,"$"

align 2
ReturnChar	dw 0a0dh
CellLenghtVar	dw 0

GlobalError	db "!FATAL: Section header was expected.",13,10
GlobalError_	db "$"

DescExpected	db "!FATAL: Descriptor was expected.", 13,10
DescExpected_	db "$"

EndFound	db "!File was compiled with no apparent problem.",13,10
EndFound_	db "$"

ImsOverFlow	db "!ImsMaker has issued an overflow error.",13,10
ImsOverFlow_	db "$"

SourceLinked	db "SOURCE FILE LINKED:
IniName         db "IMS.INI"
		db 64 DUP (0)
		db 13,10
SourceLinked_	db "$"

Separator	db "------------------------------------------------",13,10
Separator_ 	db "$"

FileCreated	db "FILE CREATED:"
FileCreated_	db "$"

align 4
		dd 0
ImaBuffer	db 16386 DUP (0)

; This is the header of the IMS file...
align 2
NbFonts		dw 0
ImagesDefVar	dw 0

ImageTreated	dw 0
FontsLenghtVar	dw 0
Rows		dw 0
Lines		dw 0
ThisSeg		dw 0
DATA   ENDS

;-----------------------------------------------------------------

IniSeg		SEGMENT 'INISEG' PUBLIC
IniBuffer	DB SizeOfIniBuffer DUP (0)
IniSeg		ENDS

;----------------------------------------------------------------
IniFile			EQU word ptr IniFileCode
MapFile			EQU word ptr MapFileCode
ImsFile			EQU word ptr ImsFileCode
DesFile			EQU word ptr DesFileCode
MxkFile			EQU word ptr MxkFileCode

CellLenght		EQU word ptr CellLenghtVar
GlobalErrorLenght 	EQU offset GlobalError_ - offset GlobalError
EndFoundLenght  	EQU offset EndFound_ - offset EndFound
SourceLinkedLenght	EQU offset SourceLinked_ - offset SourceLinked
SeparatorLenght		EQU offset Separator_ - offset Separator
FileCreatedLenght	EQU offset FileCreated_ - offset FileCreated
DescExpectedLenght	EQU offset DescExpected_ - offset DescExpected
ImsOverFlowLenght	EQu offset ImsOverFlow_ - offset ImsOverFlow

Commentaire		EQU 1
LigneBlanche		EQU 2
IdentificateurDeSection EQU 3

CopyrightLenght		EQU offset Copyright_ - offset Copyright

Return			EQU word ptr ReturnChar
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
                mov bx,offset MapName-2

XTRSN:		mov al,es:[si]
                cmp al,"."
                je DotFound
		mov [di],al
                mov [bx],al

                inc bx
		inc si
		inc di
		loop XTRSN

DotFound:

                mov si,offset _INI
                call EXT

                copymem DATA, offset IniName, DATA, offset PSP+2, 60

                mov di,bx
                mov si,offset _MAP
                call EXT

GIVE_CM_LINE:

;-------------------------------------------------------------------------

; Lire IMS.INI à l'intérieur de IniBuffer.
		OpenForRead offset IniName, IniFile
		ReadFile INISEG, 0, SizeOfIniBuffer, IniFile
		Close IniFile

; Ouverture de IMS.MAP comme fichier cible.
		Creat offset MapName, MapFile
                Write DATA, offset SourceLinked, SourceLinkedLenght, MapFile

; Lire une entrée
ReadIni:        EraseMem DATA, offset Cell,10
		Read INISEG,word ptr IniPtr, DATA, offset Cell

		call ClassEntry
                cmp bx,IdentificateurDeSection
                je Analyser

		cmp bx,-1
                jne ReadIni

EcrireErreur:	Write DATA, offset GlobalError, GlobalErrorLenght, MapFile
		Close MapFile
                Print offset GlobalError
                LeaveProgram -1

EndOfFile:	Write DATA, offset EndFound, EndFoundLenght, MapFile
                Close MapFile
                mov dx,offset EndFound

		Print offset EndFound
                LeaveProgram 0

; FONCTION ClassEntry lie le contenu de la variable Cell et détermine
;                     s'il s'agit d'un commentaire, identificateur de
;                     section, d'une ligne blanche ou d'un littéral
;		      quelconque.

; 		BX = -1 => Littéral indéfini
; 		BX =  1 => Commentaire
; 		BX =  2 => Ligne blanche
; 		BX =  3 => Identificateur de section

ClassEntry:
		call Convensions
                mov bx,-1
		mov si,offset Cell
		mov al,[si]
		cmp al,"["
		jne NotAnIdentifier
                mov bx,IdentificateurDeSection
NotAnIdentifier:

		cmp al,";"
		jse EcrireCommentaire
                cmp al,";"
                jne PasCommentaire
                mov bx,Commentaire
PasCommentaire:

		or al,al
		jse EcrireLigneBlanche
                or al,al
                jne PasLigneBlanche
                mov bx,LigneBlanche
PasLigneBlanche:

                cmp al,"["
                jne PasIdentificateurDeSection
                mov bx,IdentificateurDeSection
PasIdentificateurDeSection:
		ret

EcrireCommentaire:
		call FindCellLenght
                Write DATA,offset Cell, CellLenght, MapFile
                ret

EcrireLigneBlanche:
		mov dword ptr Cell,00000a0dh
                jmp EcrireCommentaire

; FONCTION FindCellLenght détermine la taille du littéral contenu dans
;                         la variable Cell et le retourne cette valeur
;                         dans la variable CellLenghtVar.


FindCellLenght:
		pushall
		mov si,offset Cell
FCL:		mov al,[si]
		cmp al,0
		je EndOfCell
		inc si
		jmp FCL

EndOfCell:	sub si,offset Cell
		mov word ptr CellLenghtVar,si
		popall
                ret

Analyser:

		; Au moment où "Analyser est appeler le programme à déjà
                ; engager la première phase de l'opérator. Il a trouvé
                ; un identificateur de section.

                call FindCellLenght

                cmp byte ptr Cell,"["
                jne NotSectHeader

                ToLowerCase DATA,offset Cell, 4
		mov eax, dword ptr Cell
		cmp eax, "dne["
                je EndOfFile

NotSectHeader:
                ; Parfait. À ce stade nous savons que l'identificateur
                ; n'identifie pas la fin de fichier. Donc, il s'agit
                ; bien d'un idenficateur de section.

                ; Par tradition, je vais donc écrire dans le fichier
                ; MAP l'entête de cette section.

                Write DATA, offset Separator, SeparatorLenght, MapFile
                Write DATA, offset FileCreated, FileCreatedLenght, MapFile
                Write DATA, offset Cell, CellLenght, MapFile
                Write DATA, offset Return, 2, MapFile
                Write DATA, offset Return, 2, MapFile

                mov word ptr ImaNo,0

                ; Remise à zéro du pointeur des buffers MXK et DES ainsi
                ; que leur contenu de façon à permettre la liaison
                ; correcte d'une autre librairie.

                mov word ptr MxkPtr, offset MxkBuffer
                mov word ptr DesPtr, offset DesBuffer

                EraseMem DATA, offset MxkBuffer, SizeOfMxkBuffer
                EraseMem DATA, offset DesBuffer, SizeOfDesBuffer

		mov di,offset Cell
                mov si,offset Cell+1

CopyName:
		mov al,[si]
                cmp al,"]"
                jne NotD1
                xor al,al
NotD1:
                mov [di],al
                cmp al,0
                je EndCopyName
                inc si
                inc di
                jmp CopyName

EndCopyName:

                mov si,offset _IMS
                call Ext
                call FindCellLenght
                inc word ptr CellLenghtVar
                CopyMem DATA, word ptr MxkPtr, DATA, offset Cell, CellLenght
                mov ax,word ptr MxkPtr
                add ax,CellLenght
                mov word ptr MxkPtr, ax

                ; Ouverture du fichier ????.IMS
                ; Creat offset Cell, IMSFile

		; Nous effectuons à ce stage, la lecture du nom de
                ; l'image de format IMA. Pour que l'entrée lus soit
                ; acceptable il faut:

ReadNameOfIMA:  EraseMem DATA, offset Cell, 32
		Read INISEG, word ptr IniPtr, DATA, offset Cell

		call ClassEntry

                ; qu'il ne s'agisse pas d'un identificateur de
                ; section. [xxxx]

                cmp bx,IdentificateurDeSection
                je DealWithSectionId

                ; ou d'un commentaire [;...]

                cmp bx,-1
                jne ReadNameOfIma

                ; %CellLenght%= len(%Cell%)
                call FindCellLenght

                ; Ajuster le no de l'image
		HexFrameExtender byte ptr ImaNo+1,offset ImaNoTxt
                HexFrameExtender byte ptr ImaNo, offset ImaNoTxt+2
                inc word ptr ImaNo

                ; Write %Cell%
                Write DATA, offset ImaNoTxt, 5, MapFile
                Write DATA, offset Cell, 32, MapFile


                ; %Cell%=%Cell%+".IMA"
                mov di,offset Cell
                add di,word ptr CellLenght
                mov si,offset _IMA
		call EXT

		; %MxkBuffer% = %MxkBuffer% + %Cell%
                add word ptr CellLenghtVar,5

                CopyMem DATA,word ptr MxkPtr, DATA, offset Cell,CellLenght
                mov ax,word ptr MxkPtr
                add ax,CellLenght
                mov word ptr MxkPtr, ax

		; Le programme effectuera, à ce stage, la lecture du
                ; commentaire rataché à l'image qui vient d'être lue.
                ; En fait, il ne s'agit pas d'un commentaire ordinaire,
                ; il s'agit du descripteur nominal qui identifiera
                ; l'image.

ReadDesc:	Read INISEG, word ptr IniPtr, DATA, offset Cell

                call ClassEntry

                cmp bx,LigneBlanche
                je DescFound
                cmp bx,-1
                je DescFound

                Write DATA, offset DescExpected, DescExpectedLenght, MapFile
    		Print offset DescExpected
                LeaveProgram -1

DescFound:      cmp bx,LigneBlanche
		je BlankLineSpecial

		call FindCellLenght
		Write DATA, offset Cell, CellLenght, MapFile
                Write DATA, offset Return, 2, MapFile
BlankLineSpecial:
                WriteMem DATA, word ptr DesPtr, DATA, offset Cell, CellLenght
		WriteMem DATA, word ptr DesPtr, DATA, offset RETURN, 1
                jmp ReadNameOfIma

DealWithSectionId:

		CopyMem DATA, offset DesName, DATA, offset MxkBuffer, 10
                mov di,offset DesName
LookForDot:     mov al,[di]
                cmp al,"."
                je FoundDot
                inc di
                jmp LookForDot

FoundDot:	mov si,offset _DES
		call EXT

                mov ax,word ptr DesPtr
                sub ax,offset DesBuffer
                inc ax
                mov word ptr DesSize, ax

                ; Nétoyage des tous les buffers utilisés par le
                ; système.
		EraseSeg FONT
                EraseSeg FONT2
                EraseMem LIBRAIRY, offset Images,  8192
                mov word ptr NbFonts    ,1
                mov word ptr ImagesDefVar ,0
                mov word ptr MxkPtr, offset MxkBuffer

                ; modification 20 dec 94
                mov word ptr ImaNo, 0

                ; Creat offset MxkBuffer, ImsFile

DoImaAgain:
		SkipChar DATA, word ptr MxkPtr, 0

                ; Modification 06 jan 1995
                mov di,word ptr ImagesDefVar

                ; Read name of ????.IMA
                mov si,word ptr MxkPtr
		cmp byte ptr [si],0
                je EndOfMxk

                pushall
                SetSeg <DS>, DATA
                SetSeg <ES>, DATA
                mov dx,word ptr MxkPtr	 ; Name of File
                mov bx,offset ImaBuffer-2; Destination to buffer
                mov cx,16386
                call LoadNew
                popall

                SetSeg <ES>, LIBRAIRY

                mov al,byte ptr ImaBuffer-2
                xor ah,ah
                or al,al
                jne RN256
                mov word ptr Rows,256
                jmp R_

RN256:		mov word ptr Rows,ax

R_:             mov al,byte ptr ImaBuffer-1
                xor ah,ah
                or al,al
                jne LN256
                mov word ptr Lines, 256
		jmp L_

LN256:		mov word ptr Lines,ax

L_:

                mov di, word ptr ImagesDefVar	; *** Vérifier cette ligne

                mov ax, 0
                mov cx, word ptr Lines
MulXY:          add ax, word ptr Rows
                loop MulXY

                shl ax,1	; (X*Y)*2
                add ax,6
                add ax,di

                mov  es:[di+0], ax
		movw es:[di+2], word ptr Rows
		movw es:[di+4], word ptr Lines

		add di,6

		mov word ptr ImageTreated, offset ImaBuffer

                mov cx, word ptr Lines
DealWithNextLine:push cx

		mov cx, word ptr Rows
DealWithNextFont:
                push cx
                SetSeg <FS>, FONT

                mov dx, word ptr NbFonts
                mov bx, 0
                mov ax, 0
                mov bp, 0

ScanNextFont:   mov cx,64/4
		mov si, word ptr ImageTreated
ChkFontMore:	cmpd ds:[si], fs:[bx]
                jne NotMatching
                add si,4
                add bx,4
		loop ChkFontMore
                jmp FoundMatch

NotMatching:    add bp,64		; Stored Font read
                mov bx,bp
                mov cx,dx
		dec dx			; Nb of Font to read -1
                inc ax			; CurrentFont +1
                call InFont2
		loop ScanNextFont

                mov ax, word ptr NbFonts
                call InFont2
                inc word ptr NbFonts
                mov si, word ptr ImageTreated
                mov bx,bp

                mov cx, 64/4
CopyFont:	movd fs:[bx], ds:[si]
                add bx,4
                add si,4
                loop CopyFont

FoundMatch:	mov es:[di],ax		; Font= CurrentFont
		add word ptr ImageTreated, 64
                add di,2

                pop cx
		loop DealWithNextFont

		pop cx
                loop DealWithNextLine

		; *** Correction apportée le 4 déc 94
                mov word ptr ImagesDefVar, di
                ; ***

		jmp DoImaAgain

; FUNCTION InFont2: Cette fonction a pour but de déterminer s'il y a eut
;                   un dépassement du segment FONT2. Si tel est le cas,
; 		    elle change de segment pour permettre l'écriture ou
;                   la lecture continue via les deux segments.

InFont2:	cmp ax,1024
		jb RetIF2
       		SetSeg <FS>, FONT2

                cmp ax,2048
                jb RetIF2
		SetSeg <FS>, FONT3

                cmp ax,3072
                jb RetIF2
                SetSeg <FS>,FONT4

                cmp ax,4096
                jb RetIF2

                Write DATA, offset ImsOverflow, ImsOverFlowLenght ,MapFile
                Print offset ImsOverflow
                LeaveProgram -1

RetIF2:		ret


		; The program has reach a nul char in the mxk buffer
                ; so it is about time to close the damn file, no ?

EndOfMxk:

		mov word ptr es:[di],0
                add di,2
		mov word ptr ImagesDefVar, di
                add word ptr ImagesDefVar, 4

                Creat offset MxkBuffer, ImsFile
		Write DATA, offset NbFonts, 4, ImsFile

                sub word ptr ImagesDefVar, 4
		Write LIBRAIRY, 0, word ptr ImagesDefVar, ImsFile

                mov word ptr ThisSeg, FONT
	        mov ax, word ptr NbFonts
IsFull:         cmp ax,1024
                jb OkThrow

		Write word ptr ThisSeg, 0, 65535, ImsFile

                sub ax,1024
                add word ptr ThisSeg, 65536/16
                jmp IsFull

OkThrow:        shl ax,6
		mov word ptr FontsLenghtVar, ax
                Write word ptr ThisSeg, 0, word ptr FontsLenghtVar, ImsFile

                Write DATA, offset DesSize, 2,ImsFile
                Write DATA, offset DesBuffer, word ptr DesSize, ImsFile

        	Write DATA, offset Copyright, CopyrightLenght, ImsFile

		Close ImsFile
		jmp Analyser

CONVENSIONS PROC NEAR
		push dx
		mov dx,DATA
		mov ds,dx
		pop dx
		ret
CONVENSIONS ENDP

; -----------------------FIN DU PROGRAMME-----------------------
VLAMITS    ENDP                           ; Fin de la procedure
CODE ENDS                                ; Fin du programme
END     VLAMITS                           ; Point d'entree
;---------------------------------------------------------------
