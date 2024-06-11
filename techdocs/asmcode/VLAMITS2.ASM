;----------------------------------------------------------------
;       LES VLAMITS II
;       par Francois Blanchette
;----------------------------------------------------------------

INCLUDE C:\MASM61\LISTING\SSFSM95.INC
INCLUDE C:\MASM61\LISTING\IOSYSTEM.INC

; Enables all externals definitions...
UseRepV2        ; 94REPV2.ASM
UseSTATV2       ; 94STATV2.ASM
UseColors       ; 95COLORS.ASM
UseSTATV2_1     ; 95STV2_1.ASM
UseVGAHI        ; 95VGAHI.ASM
UseStrings      ; 95STRING.ASM

;----------------------------------------------------------------
ShowAL  MACRO
	Locate 0,0
	mov byte ptr TestVar,al
	printx byte ptr TestVar
	ENDM

;----------------------------------------------------------------
IfKeyDo MACRO Label
Local   OUT_

	or ax,ax
	jne Label

	ENDM

;----------------------------------------------------------------
HexFrameExtender MACRO Value, Frame
Local           ALNotABC, ALNotABC_

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
ALNotABC:       mov [di+1], al


		mov al,Value
		shr al,4
		and al,15
		add al,30h

		cmp al,3ah
		jb ALNotABC_
		sub al,3ah
		add al,65
ALNotABC_:      mov [di],al

		popall
		ENDM

;------------------------------------------------------------
printx  MACRO Value_
	HexFrameExtender Value_, offset Frame_
	print offset Frame_
	ENDM
;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------
Size_DAT        EQU 8196/2
MsgsSize        EQU 2040
CtVoiceSize     EQU 32765
SoundDataSize   EQU 32765
;----------------------------------------------------------------
DATA      SEGMENT PUBLIC 'DATA'
align 4
MapData         db 32768 DUP (0)
CARS            db 4096 DUP (5)
COPYRIGHT       db "LES VLAMITS II: (C) 1995 FRANCOIS BLANCHETTE "
COPYRIGHT_      db 0
INTRO_SCR       db "VLAMITS2.SCR",0
INTRO_IMS       db "VLAMITS2.IMS",0
VlAMITS2_MSG    db "VLAMITS2.MSG",0
VLAMITS2_TMP    db "VLAMITS2.TMP",0
VLAMITS2_IMA    db "VLAMITS2.IMA",0
DEFAULT_PAL     db "DEFAULT.PAL",0
PREPAREZ_IMA    db "PREPAREZ.IMA",0
HISCORES_VLA    db "HISCORES.VLA",0
NameRecFile     db "RECORD.DAT",0
DEMO_DAT        db "DEMO.DAT",0
CTVoIce_DRV     db "C:\SB16\DRV\CT-VOICE.DRV",0
		db 128 DUP (0)
CTVOICE_DRV_NAME db "CT-VOICE.DRV",0

; VOC FILES
VLAMITS2_VOC    db "SOUNDS\!vlamits.VOC",0
_5000PTS_VOC	db "SOUNDS\!5000PTS.VOC",0
JUMP_VOC	db "SOUNDS\!JUMP.VOC",0
METAL_VOC	db "SOUNDS\!METAL.VOC",0
OUCH_VOC	db "SOUNDS\!OUCH.VOC",0
TRANSP_VOC	db "SOUNDS\!TRANSP.VOC",0
WALK_VOC	db "SOUNDS\!WALK.VOC",0
VOC_NAME	db 128 DUP (0)
_SOUND		db "sounds",0
_VOC		db ".VOC",0
_BLASTER	db "blaster",0



; LISTE DES MESSAGES D'ERREURS
RecJoueurEchec  db "FATALE: Acteur principal absent du script maitre."
		db 10,13,"$"
XFleurTxt       db "FATALE: Objet 0x11 absent.",10,13,"$"
TransErrTxt     db "FATALE: Objet associé ",34,"ATT=task_dest",34," manquant."
		db 10,13,"$"
PtsTxt          db "points",0
FleursTxt       db "fleurs",0
QueteTxt        db "commence ta quete",0
VlamitsHighBoard  db "+00table des guerriers vaillants",0
EcrireVotreNomTxt db "+05ecrire votre nom et puis "
		  db 34, "retour",34,".",0
ChouxPasBonTxt    db "+05votre incompetence sera legendaire.",0
SpaceToCont     db "+05appuyer sur ",34, "espace",34," pour continuer.",0
Bonus5000TR     db "+03bonus 5000pts _ avoir tout ramasse",0
TricherTxt      db "+02aucun bonus _ tricher",0
DemoTxt         db "demo",0
HiCreatErrorTxt db "+06incapable de reecrire ",34,"hiscores.vla",34," .",0
HiLoadErrorTxt  db "+06incapable de lire ",34,"hiscores.vla",34," .",0
EndSectionTxt   db "+09section completee",0
SectionBonusTxt db "+04bonus pour execelente performance",0
NoSectionBonusTxt db"+04performance +- acceptable!",0
SaveGame_XXX    db "SAVEGAME.000"
SaveGame_XXX_   db 0,"$"
RestoreErrortxt db "Incapable de restorer cette partie!$"

TmpErrorTxt db "FATALE: Incapable de reecrire fichier temporaire.",13,10,13,10
		db "Solution: Verifier si votre unite n'est pas plein ou ",13,10
		db "proteger contre l'ecriture.",13,10,"$"
SbNotFoundTxt   db "ERREUR: Carte SB -- Introuvable.$"
SbAddXTxt       db "ERREUR: Addresse du port incorrecte.$"
SbIntXTxt       db "ERREUR: Interruption incorrecte.$"
sbErrInc        db "ERREUR: Inconnue.$"
sbFoundTxt      db "Pilote CT-VOICE.DRV initialiser.$"
sbDriverInfo    db "Si vous disposez d'une SB-PRO OU SB-16, "
		db "creer, si il n'existe pas, le repertoire "
		db "C:\SB16\DRV\ et copier le fichier CT-VOICE.DRV "
		db "dans celui-ci.$"

sbGenericInfo	db 13,10,13,10,"Ce programme fonctionnera SEULEMENT avec"
		db " une carte SoundBlaster connecter sur le port"
                db " 220h avec l'interruption 5 (IRQ5).",10,13
		db "Appuyer sur une touche pour continuer.$"

ASCII_TABLE     db " abcdefghijklmno"
		db "pqrstuvwxyz01234"
		db "56789*#ABCDEFGH!"
		db "._,:",34,"#+-",0

align 2
Intro_Pg        dw 20,20,26,22,21
SkyColors       db 9,1,105,104,127,176
		db 177,198,199,255,0,0,0,0

Cl1             db 0,0,0
Cl2             db 0,0,0
Cl3             db 0,0,0
Cl4             db 0,0,0
Bkc             db 0,0,0

HiScores        db 40*21 DUP (0)
CosTable        db EnHaut,AGauche,ADroite, EnBas
		db EnBas,ADroite,AGauche, EnHaut
		db EnBas,AGauche,EnBas,ADroite
		db EnHaut,EnBas,ADroite,AGauche

CannibalDAT     db AGauche, EnBas, ADroite, EnHaut
		db ADroite, EnBas, AGauche, EnHaut

		;db AGauche,ADroite, EnHaut,EnBas
		;db ADroite,AGauche, EnBas, EnHaut
		;db EnBas,EnHaut, AGauche,ADroite
		;db EnHaut,EnBas, ADroite,AGauche

_DAT            db Size_DAT DUP (0)
Nom_DAT         db "Facile.DAT",0
		db "Avance.DAT",0
		db "Difficil.DAT",0
		db "ancien.DAT",0
Nom             db 128 DUP (0)

align 2
RecInProgress   dw FAUX
DemoOn          dw FAUX

StopFrame       dw 0
BloquerFrame    dw 0
BlankFrame      dw 0
_PtsFrame       dw 0
CannibalBaseFrame dw 0
InMangaBaseFrame dw 0
FleaBaseFrame   dw 03eh

NbrFleurs       dw 0
WhileUnderWater dw 0

; TMP -- START
NbrFleursFrame  db 0,0
BiteDelai       db 0
LevelOption     db 0
GameDoodle      db 0

align 2
Frame_          dw 0,"$"
NomPtr          dw 0
OldNomPtr       dw 0
HHiFile         dw 0
HTmpFile        dw 0

NbJoueurs       db 1            ; Nbr de joueurs
Diff            db 0            ; Niveau de difficulté
AniFlag         db 0            ; Animation flag
TestVar         db 0

align 2
IAniFlag        dw 0
BaseActFrame    dw 0            ; 1ere image d'ANNIE (1er personnage)
PlyBaseFrame    dw 0            ; 1ere image du JOUEUR
P1Shape         dw 0            ; No du personnage incarné par PLY1
P2Shape         dw 0            ; No du personnage incarné par PLY2

PlyBaseImage    dw 0            ; Image de base du PLY1
PlyAFlag        dw 0            ; Indicateur de mouvement de PLY1
PlyPtr          dw 0            ; Ptr sur PLY1
PlyDir          dw 0            ; Direction vers laquelle PlY1 pointe
PlyBite         dw 0            ; Indique si PLY1 à été mordu
PlyOxygen       dw 0            ; Indique la quantité d'oxygène
PlyLifeForce    dw 0            ; Force de vie de PLY1
PlyNbVies       dw 0            ; Nbr Vie pour PLY1
PlyScore        db 8 DUP (0)    ; Score de PLY1

PlyJumpFlag     dw 0            ; Indicateur de saut
PlyFallFlag     dw 0            ; Indicateur de chute

CTimer          dw 0            ; Compteur pour les créatures
CValve          dw 0            ; Permet l'ouverture intermitente
HRecFile        dw 0            ; Handle du fichier RECORD.XXX
RecBuffer       dw 0            ; Buffer de transfer avec le
				; disque RECORD.XXX
ZeroCounter     dw 0            ; Compteur d'octect NUL
SelectTimer     dw 0            ; Temps inactif de l'écran de
				; sélection
NoShow          dw 0            ; Si NoShow==VRAI alors le démo
				; sera halté.
EndData         db 0

align 2
HSFile          dw 0
DataSize        dw 0
RestoreGame     dw 0

; LES VARIABLES SUIVANTES SE REFÈRFENT À lA CARTE SB.
HCtvFile        dw 0
SB_ACTIVE       dw FAUX
StatusWord      dw FAUX
HasSound 	dw 0
HasBlaster 	dw 0

DATA   ENDS
;----------------------------------------------------------------
SCREEN2 SEGMENT
               db 22*0a00h DUP (0)
SCREEN2 ENDS
;----------------------------------------------------------------
Msg     SEGMENT
		db MsgsSize DUP (0)
Msg     ENDS
;----------------------------------------------------------------
CtVoice SEGMENT PUBLIC 'CODE'
CtVoice ENDS
;----------------------------------------------------------------
; CONSTANTES
; [DIRECTIONS]
EnHaut                  EQU 0
EnBas                   EQU 1
AGauche                 EQU 2
ADroite                 EQU 3
SautAGauche             EQU 12h
SautADroite             EQU 13h
OnSite                  EQU 20h

; [CONSTANTES RELIÉES AU SCRIPTE]
ScrAtt                  EQU 0
ScrStat                 EQU 1
ScrU1                   EQU 2
ScrU2                   EQU 3
ScrIma                  EQU 4
ScrX                    EQU 6
ScrY                    EQU 7

ImaNxPtr                EQU 0
ImaLen                  EQU 2
ImaHei                  EQU 4

; [OBJECTS CLASSES]
Blank                   EQU 0
Player                  EQU 1
Oxygen                  EQU 3
Transporter             EQU 4
Diamant                 EQU 10h
Fleur                   EQU 11h
Fruit                   EQU 12h
Mushroom                EQU 13h
Misc                    EQU 14h
DeadlyItem              EQU 15h

Fish                    EQU 0c0h
VCrea                   EQU 0c1h
VampirePlant            EQU 0c2h
FlyPlat                 EQU 0c3h
Spider                  EQU 0c4h
Cannibal                EQU 0c5h
InManga                 EQU 0c6h
GreenFlea               EQU 0cfh

Ladder                  EQU 0d0h
Bridge			EQU 0d2h
LadderDing		EQU 0d3h

Sand                    EQU 0ddh
TopWater                EQU 0deh
BottomWater             EQU 0dfh
ObstacleClass           EQU 0e0h
StopClass               EQU 0f0h
Lava                    EQU 0ffh

; [GAME PREDEFINES]
FishLeft                EQU 0
FishRight               EQU 1
Faux                    EQU 0
Vrai                    EQU 1
TRUE                    EQU al==Vrai
FALSE                   EQU al==Faux

GameSpeed               EQU 16384/2
SelectTime              EQU 500

QteOxygenNormal         EQU 64
QteLifeForceNormal      EQU 128
QteLivesNormal          EQU 5
MaxLifeForce            EQU 8192
MaxOxygen               EQU 256
TimeForOxygenLost       EQU 2

FishDrain               EQU 20
PlantDrain              EQU 4
VCreaDrain              EQU 4
InMangaBite             EQU -1
FleaDrain               EQU 4
FlowerEnergy            EQU 6
OxygenAdd               EQU 2
OxygenDrain             EQU 1
LifeDrowning            EQU 2
NeedleDrain             EQU 32

MaxColonnes             EQU 40
MaxLignes               EQU 25

; [CARACTÈRES USER-DEFINED]
CAR_A                   EQU 1
CAR_0                   EQU 27
CAR_FLEUR               EQU 37
CAR_BONHOMME            EQU 38
CAR_TOPLFCORNER         EQU 39
CAR_TOPBORDER           EQU 40
CAR_TOPRGCORNER         EQU 41
CAR_LFBORDER            EQU 42
CAR_RGBORDER            EQU 43
CAR_BOTTOMRGCORNER      EQU 44
CAR_BOTTOMBORDER        EQU 45
CAR_BOTTOMLFCORNER      EQU 46
CAR_CURSEUR             EQU 16*3+5

; [NAMES DIRECTIVES]
PlayerCar               EQU "*"
BlankImaCar             EQU "_"
StopImaCar              EQU "!"
BrickImaCar             EQU "#"
YoungCannibalCar        EQU "\"
InMangaCar              EQU "±"

; [TABLE DE POINTAGES]
_10PTS                  EQU 0
_15PTS                  EQU 1
_25PTS                  EQU 2
_50PTS                  EQU 3
_100PTS                 EQU 4
_200PTS                 EQU 5
_400PTS                 EQU 6
_500PTS                 EQU 7
_1000PTS                EQU 8
_5000PTS                EQU 9
_10000PTS               EQU 10

; [TÂCHE EFFECTIVE D'UN OBJ.]
Task_none               EQU 0
Task_remove             EQU 1
Task_source             EQU 2
Task_dest               EQU 3
Task_change             EQU 4
Task_messager           EQU 5

NameXPos                EQU 9
YBonus5000TR            EQU 20
EndSectionY             EQU 14
YSectionBonus           EQU 16
FirstLevel              EQU 1
SectionCompleted        EQU 9

RecOnKey                EQU "0"
DemoKey                 EQU "!"
RecFile                 EQU word ptr HRecFile
HiFile                  EQU word ptr HHiFile
TmpFile                 EQU word ptr HTmpFile
SFile                   EQU word ptr HSFile

IntPlyBaseFrame         EQU 0abh
StartTmp                EQU offset NbrFleursFrame
EndTmp                  EQU offset EndData
GameTamponSize          EQU EndTmp - StartTmp

NbPlyTypes              EQU 10
VlaColors               EQU offset O_Registers + (5*8+1)*3
EpsColors               EQU offset O_Registers + (1*8+1)*3
BkcColors               EQU offset O_Registers + (0*8+1)*3

; [CtVoice DRIVER]
CtvFile                 EQU word ptr HCtvFile
const_GetCtVoiceVersion EQU 0
const_InitCtVoice       EQU 3
const_ActivateSpeaker   EQU 4
const_AddressStatWORD   EQU 5
const_ReadSample        EQU 6
const_StopSample        EQU 8

; [Sound Samples]
HEADER_SIZE		EQU 1ah
jump_size		EQU 2400
metal_size		EQU 2400
Ouch_size		EQU 8200
Transp_size		EQU 7600
walk_size		EQU 1200

snd_Jump		EQU 0
snd_metal		EQU snd_Jump+ jump_size
snd_ouch		EQU snd_metal+ metal_size
snd_transp		EQU snd_ouch+ ouch_size
snd_walk		EQU snd_Transp+ Transp_Size

;----------------------------------------------------------------
CODE SEGMENT PUBLIC 'CODE'
.386
;----------------------------------------------------------------
CtVoiceDrv      PROC FAR
		db CtVoiceSize DUP (0)
CtVoiceDrv      ENDP
;----------------------------------------------------------------

;----------------------------------------------------------------
; Pause:
; Cette fonction suspent l'exécution du program pendant un delai
; déterminé. La fonction peut-être abortée par l'exécution d'une
; touche.
; Paramètre de sortie:
; AX = Code de clé étendue
;----------------------------------------------------------------
Pause           MACRO Lenght
		invoke _Pause, Lenght
		ENDM

_Pause          PROTO NEAR PASCAL  Lenght:WORD
_Pause          PROC NEAR PASCAL, Lenght:WORD

		push cx
		push dx
		mov dx, Lenght
P2:             mov cx,4096
		call Getax
		ifkeyDo out_
P:              mul al
		loop P

		mov cx,dx
		dec dx
		loop P2

Out_:           pop dx
		pop cx
		ret
_Pause          ENDP
;------------------------------------------------------------------

LoadVOC MACRO FName, TFONT, TZone
		invoke _LoadVOC, FName, TFONT,TZone
	ENDM

_LoadVOC PROTO  PASCAL :WORD, :WORD, :WORD
_LoadVOC PROC PASCAL, FName:WORD, TFONT:WORD ,TZone:WORD
Local           VocFile:WORD

                HSetHandler XVocHandler
		HOpenForRead FName, VocFile
		HReadFile TFONT, TZone, SoundDataSize, VocFile
		HClose VocFile
                HSetHandler EHandler
		ret

XVocHandler:    set ds,DATA
		mov SB_AcTIVE, FAUX
                HSetHandler EHandler
		ret


_LoadVOC ENDP

;----------------------------------------------------------
SayLevelName PROC
Local		NamePtr:WORD

		set ds,DATA
		movw word ptr NamePtr, word ptr NomPtr
                Skipchar DATA, NamePtr, 10		; Level Name
                Skipchar DATA, NamePtr, 10		; IMS

                Read DATA, NamePtr, DATA, offset VOC_NAME
                copymem DATA, offset VOC_NAME, DATA, offset _SOUND, 6

                set ds, DATA
                mov di, offset VOC_NAME+13
                mov si, offset _VOC
                call EXT

                HSetHandler SLN_EHandler
                LoadVOC offset VOC_NAME, FONT3, 0
                .if SB_ACTIVE==VRAI
			pushall
			set es, FONT3
			mov di, 1ah + 0
			mov bx, Const_ReadSample
			call CTVoiceDRV
			popall
                .endif

SLN_EHandler:	HSethandler EHandler

                ret

SayLevelName ENDP


;----------------------------------------------------------------

ChangeScrSize PROC
		pushall
		set es,LIBRAIRY
		mov si,offset ScrDefs
		.while word ptr es:[si] != -1
		     add si,8
		.endw
		sub si, offset ScrDefs
		mov word ptr ScriptSize, si

		popall
		ret
ChangeScrSize ENDP

;----------------------------------------------------------------
CopyScr         MACRO Dest, source
		invoke _CopyScr, Dest,Source
		ENDM

_CopyScr       PROTO NEAR PASCAL  Dest:WORD, Source:WORD
_CopyScr       PROC NEAR PASCAL, Dest:WORD, Source:WORD
		push cx
		push di
		push dx
		push es
		push fs

		mov di,0
		mov dx,Source
		mov es,dx
		mov dx,Dest
		mov fs,dx
		mov cx, (21*0a00h) /4

_CS:            mov eax,es:[di]
		mov fs:[di],eax
		add di,4
		loop _CS

		pop fs
		pop es
		pop dx
		pop di
		pop cx
		ret

_CopyScr        ENDP

;----------------------------------------------------------------------
; RepositionnerPly:
; Cette procédure s'assure que le joueur est bien placé sur la 9ième ligne
; de l'écran. Dans le cas contraire, des mesures seront prises pour
; rectifier la situation.
;----------------------------------------------------------------------
RepositionnerPLY PROC
Local           Modification: WORD

		mov Modification,FAUX
		push ax
		push si

		ifndo byte ptr PlyJumpFlag,0, Bye_

		set es,LIBRAIRY
		mov si,word ptr PlyPtr
		mov al,es:[si+ScrY]

		.if byte ptr MY < al
			sub al,byte ptr MY
			cmp al,9
			ja INC_MY
			jb DEC_MY
			jmp Bye
		.else
DEC_MY:                .if byte ptr MY !=0
				call ScrollUp
				dec byte ptr MY
				mov Modification, VRAI
				;call DessinerBck
				;call DrawFow
				;call PickUp
				jmp Bye
			.endif
		.endif

INC_MY:
		.if byte ptr MY > 5
			call ScrollDn
			inc byte ptr MY
			mov Modification, VRAI
			;call DessinerBck
			;call DrawFow
			;call PickUp

		.endif
Bye:
		mov al, byte ptr es:[si+ScrX]
		.if al< byte ptr MX
			call ScrollLf
			dec byte ptr MX
			mov Modification, VRAI

		.else
		     sub al,byte ptr MX
		     .if al<10 && (byte ptr MX!=0)
			call ScrollLf
			dec byte ptr MX
			mov Modification, VRAI
		     .endif

		.endif

		.if Modification==VRAI

			CopyScr SCREEN2, SCREEN
			pushall
			set gs,SCREEN2
			set es,LIBRAIRY
			mov si,Chgingdefs
			call DrawScript
			popall
			CopyScr 0a000h, SCREEN2
		.endif

Bye_:
		pop si
		pop ax
		ret
RepositionnerPLY ENDP
;------------------------------------------------------------------------
; _TagFont X, Y, FONT   (X,Y = STANDARD! - G.Gaudreau:"Hein!" ).
; Affiche un caractère à la coordonnée spécifiée.
;------------------------------------------------------------------------
TagFont         MACRO X,Y,FONT_, Color
		invoke _TagFont, X,Y, FONT_, Color
		ENDM

_TagFont        PROTO NEAR PASCAL  X:BYTE,Y:BYTE, FONT_:BYTE, COLOR:BYTE
_TagFont        PROC NEAR PASCAL, X:BYTE,Y:BYTE, FONT_:BYTE, COLOR:BYTE
		push ax
		push cx
		push di
		push dx
		push gs
		push si

		set gs,0a000h

		mov al,Y
		mov ah,0ah
		mul ah
		shl ax,8
		mov di,ax

		mov al,X
		mov ah,0
		shl ax,3
		add di,ax

		mov al,Font_
		mov ah,0
		shl ax,6
		mov si,ax
		add si,offset CARS

		mov dx,8
A2:             mov cx,8
A1:             mov al,[si]
		ifzdo al,Noir
		ifedo al,13h,Noir
		add al,Color
Noir:           mov gs:[di],al
		inc si
		inc di
		loop A1

		add di,140h-8
		mov cx,dx
		dec dx
		loop A2

		pop si
		pop gs
		pop dx
		pop di
		pop cx
		pop ax
		ret
_TagFont        ENDP

;-------------------------------------------------------------------------
; DrawBar:
; La fonction draw bar affiche une bar horizontal d'une taille spécifié,
; d'une couleur spécifique à une coordonnée spécifique.
;-------------------------------------------------------------------------
DrawBar         MACRO Taille, COLOR,Y
		invoke _DrawBar,Taille,Color,Y
		ENDM

_DrawBar        PROTO NEAR PASCAL  Taille:WORD, Color:BYTE,Y:BYTE
_DrawBar        PROC NEAR PASCAL, Taille:WORD, Color:BYTE,Y:BYTE
		pushall

		set gs,0a000h
		mov al,0ah
		mov ah,Y
		mul ah
		shl ax,8
		mov di,ax               ; DI = PtrDest

		mov cx,(0a00h-140h*2)/4
		xor eax,eax
		mov bx,140h
DB_3:           mov gs:[di+bx],eax
		add bx,4
		loop DB_3

		mov dx,Taille
		shr dx,1
		or dx,dx
		je Bye
		mov al,Color

		mov bx,140h

DB_2:           mov cx,6
DB_:            mov gs:[di+bx],al
		add bx,140h
		loop DB_

		sub bx,(140h*6)-1
		dec dx
		or dx,dx
		jne DB_2

Bye:            popall
		ret
_DrawBar        ENDP

;-----------------------------------------------------------------------
; AjusterFleurFrame:
; Cette procédure sert à ajuster les frames de Nbr de Fleur.
;-----------------------------------------------------------------------
AjusterFleurFrames PROC

		push si

		mov si, offset NbrFleursFrame+1
		mov byte ptr [si],0
		mov byte ptr [si-1],0
		addb [si], byte ptr NbrFleurs

ChkNx:          cmp byte ptr [si],10
		jb Bye
		sub byte ptr [si],10
		inc byte ptr [si-1]
		dec si
		jmp ChkNx

Bye:            cmp si, offset NbrFleursFrame+1
		je Bye_
		mov si,offset NbrFleursFrame+1
		jmp ChkNx
Bye_:
		add byte ptr NbrFleursFrame, Car_0
		add byte ptr NbrFleursFrame+1, Car_0
		pop si
		ret
AjusterFleurFrames      ENDP

;-----------------------------------------------------------------------
; _DrawString:
; Cette procédure sert à afficher une chaine de caractère à l'écran.
;-----------------------------------------------------------------------
DrawString      MACRO x,y, DSEG, Source, Color
		invoke _DrawString, x,y, DSEG, Source, Color
		ENDM

_DrawString     PROTO NEAR PASCAL x:BYTE,y:BYTE,DSEG:WORD,Source:WORD,Color:BYTE
_DrawString     PROC NEAR PASCAL, x:BYTE,y:BYTE,DSEG:WORD,Source:WORD,Color:BYTE
Local           ThisFont: BYTE
		pushall
		set es,DSEG
		set si,Source

Nx:             mov al,byte ptr es:[si]
		ifedo al,0, Bye

		mov bx,offset ASCII_TABLE
NxChar:
		ifedo byte ptr [bx],0, EndOfTable
		ifedo byte ptr [bx],al, MatchFound
		inc bx
		jmp NxChar

EndOfTable:     mov bx,offset ASCII_TABLE
MatchFound:     sub bx,offset ASCII_TABLE
		mov al,bl
		jmp Put

Put:
		mov ThisFont,al
		TagFont x,y, ThisFont, color
		inc si
		inc x
		jmp Nx


Bye:            popall
		ret
_DrawString     ENDP

;-----------------------------------------------------------------------
; _AfficherTitre:
; Cette fonction affiche le titre d'un tableau et cela en la couleur
; spécifiée dans la chaine elle-même. La chaine affichée sera centrée.
;-----------------------------------------------------------------------
AfficherTitre   MACRO y, DSEG, Source
		invoke _AfficherTitre, y, DSEG, Source
		ENDM

_AfficherTitre  PROTO NEAR PASCAL y:BYTE,DSEG:WORD,Source:WORD
_AfficherTitre  PROC NEAR PASCAL, y:BYTE,DSEG:WORD,Source:WORD
Local           Color:BYTE
Local           x:byte

		pushall
		set es, DSEG
		mov si,Source
		mov al,byte ptr es:[si+1]
		sub al,30h
		mov ah,10
		mul ah

		mov ah, byte ptr es:[si+2]
		sub ah,30h
		add al,ah

		mov ah,0
		actife byte ptr es:[si], "-", <sub ah,al>
		actife byte ptr es:[si], "+", <mov ah,al>
		mov Color, ah

		add si, 3
		StrLen DSEG, si
		mov bl,40
		sub bl,al
		shr bl,1
		mov x,bl

		DrawString x,y, DSEG, si, color

		popall
		ret
_AfficherTitre  ENDP

;-----------------------------------------------------------------------
; _DrawMsg:
; Cette procédure affiche un message à partir de la table des messages.
; Paramètres d'entrée
; NoMsg : No du message à afficher.
;----------------------------------------------------------------------

DrawMsg         MACRO NoMsg, y
		invoke _DrawMsg, NoMsg, y
		ENDM

_DrawMsg        PROTO NEAR PASCAL NoMsg:WORD, y:BYTE
_DrawMsg        PROC NEAR PASCAL, NoMsg:WORD, y:BYTE
Local           MsgPtr:WORD
Local           Color:BYTE
Local           x: byte

		push es
		pusha

		mov MsgPtr, 0
		set es,MSG
		ifedo NoMsg,0, FoundPtr
		mov cx,NoMsg
NxMsg:          skipchar MSG, MsgPtr, "@"
		loop NxMsg

FoundPtr:

		mov si,MsgPtr
		mov al,byte ptr es:[si+1]
		sub al,30h
		mov ah,10
		mul ah

		mov ah, byte ptr es:[si+2]
		sub ah,30h
		add al,ah

		mov ah,0
		actife byte ptr es:[si], "-", <sub ah,al>
		actife byte ptr es:[si], "+", <mov ah,al>
		mov Color, ah
		add MsgPtr,3+2

NxLine:
		StrLen Msg, MsgPtr
		mov bx,40
		sub bx,ax
		shr bx,1

		mov x, bl
		DrawString x,y,Msg,MsgPtr,color
		skipchar Msg, MsgPtr, 10
		inc y
		;DrawString x,y,Msg,MsgPtr,color

		mov si,MsgPtr
		ifedo byte ptr es:[si],"@",Bye
		jmp NxLine
Bye:
		popa
		pop es
		ret

_DrawMsg        ENDP

;-----------------------------------------------------------------------
; HiScoreSys:
; Cette procédure sert à faire une mise à jour du SCORE BOARD, en
; ajoutant le pointage et le nom d'une nouveau joueur. Sans oublier que
; ce système appelle une autre procédure qui affiche le SCORE BOARD.
;-----------------------------------------------------------------------
HiScoreSys      PROTO NEAR PASCAL
HiScoreSys      PROC NEAR PASCAL
Local           HiScorePtr: WORD
Local           Color: BYTE
Local           y:BYTE
Local           x:BYTE
Local           thisfont:BYTE

		mov y, 21 + 2 -1
		mov color, 1 + 21 -1
		mov HiScorePtr, offset HiScores + 19*40
		mov cx,20

NxFrame:        strcmpi DATA, offset PlyScore, DATA, HiScorePtr, 8
		cmp al,80h
		jae TooLarge
		ifzdo al,TooLarge
		sub HiScorePtr, 40
		dec color
		dec y
		loop NxFrame
		add HiScorePtr,40
		jmp PlaceScore

TooLarge:       ;drawmsg 2,3
		;showal
		add HiScorePtr,40
		cmp HiScorePtr, offset HiScores + 19*40
		ja NotInScoreBoard

PlaceScore:     ;locate 3,0
		;printx cl
		;showal
		mov si, offset HiScores+ 19*40
NxPS:           cmp si, HiScorePtr
		jb PlaceFound
		mov cx,40
PS:             mov al,[si]
		mov [si+40],al
		inc si
		loop PS

		sub si,80
		jmp NxPS

PlaceFound:     mov si, HiScorePtr
		mov cx,40
PF:             mov byte ptr [si],0
		inc si
		loop PF

		copymem DATA, HiScorePtr, DATA, offset PlyScore,8
		call DrawBoard
		AfficherTitre 23, DATA, offset EcrireVotreNomTxt

		mov x, NameXPos
		add HiScorePtr, NameXPos

TagCursor:
		TagFont x,y, CAR_CURSEUR, color
Ignore:
		call getax
		ifedo al,13, bye
		actife al,8, <ifndo x,NameXPos,BackSpace>
		ifedo x, 38, Ignore
		ifzdo al, Ignore
		;ifindo al,"A","H",Ignore
                actifin al,"A","Z",<add al,-"A"+"a">

		mov byte ptr ThisFont, 0
		mov si, offset ASCII_TABLE
ChkASCTable:    ifedo al,[si], FoundMatch
		ifedo byte ptr [si],0, Ignore
		inc si
		jmp ChkAscTable
FoundMatch:     mov di, HiScorePtr
		mov [di],al
		sub si, offset ASCII_TABLE
		mov ax,si
		mov ThisFont,al
		TagFont x,y, ThisFont, color

		inc x
		inc HiScorePtr
		jmp TagCursor


BackSpace:      mov di,HiScorePtr
		mov byte ptr [di],0
		TagFont x,y, 0,0
		dec x
		dec HiScorePtr
		jmp TagCursor

bye:            mov di,HiScorePtr
		mov byte ptr [di],0
		TagFont x,y,0,0
		erasemem 0a000h, 0a00h*23, 0a00h

		HSetHandler HiCreatError
		HCreat offset HiScores_VLA, HiFile
		HWrite DATA, offset HiScores, 20*40, HiFile
		HClose HiFile

		HSetHandler EHandler
		pause 5000
		ret

HiCreatError:
		erasemem 0a000h, 0a00h*23, 0a00h
		AfficherTitre 23, DATA, offset HiCreatErrorTxt
		pause 65000
		ret

NotInScoreBoard:
		mov HiScorePtr, offset HiScores + 19*40
		call DrawBoard
		AfficherTitre 23, DATA, offset ChouxPasBonTxt
		pause 15000
		ret


HiScoreSys      ENDP

;---------------------------------------------------------------------------
; DrawBoard:
; Cette procédure sert à afficher la tableau des high scores.
;---------------------------------------------------------------------------
DrawBoard       PROTO NEAR PASCAL
DrawBoard       PROC NEAR PASCAL
local           LinePtr:WORD
Local           y: BYTE
Local           color:BYTE

		AfficherTitre 0, DATA, offset VlamitsHighBoard

		mov LinePtr, offset HiScores
		mov y,2
		mov color,1


		mov dx,20
NxLine:
		mov si, LinePtr
		mov cx, 8
NxCar:          mov al,[si]
		add al,48
		mov [si],al
		inc si
		loop NxCar

		ReplaceChar DATA, LinePtr, 39 ,0, 20
		DrawString 0,y, DATA, LinePtr, Color

		mov si, LinePtr
		mov cx, 8
NxCar_:         mov al,[si]
		sub al,48
		mov [si],al
		inc si
		loop NxCar_
		ReplaceChar DATA, LinePtr, 39, 20, 0

		inc byte ptr color
		inc byte ptr y
		add lineptr, 40

		mov cx,dx
		dec dx
		loop nxLine
		ret

DrawBoard       ENDP

;----------------------------------------------------------------
; IsPlayerInLava:
; Vérifie si je joueur baigne dans la lave,
;----------------------------------------------------------------

IsPlayerInLava  MACRO
		call _IsPlayerInLava
		ENDM

_IsPlayerInLava PROC
		push cx
		push es
		push si
		set es, LIBRAIRY
		mov si, word ptr PlyPtr

		mov cx,2
		mov si, word ptr es:[si+ScrX]

		mov al, Faux
Nx:             actife byte ptr [si], Lava, <mov al,Vrai>
		inc si
		loop Nx

		pop si
		pop es
		pop cx
		ret

_IsPlayerInLava ENDP

;----------------------------------------------------------------
; _IsPlayerThere:
; cette fonction vérifie si le joueur se situe à une position donnée
; de la créature.
;----------------------------------------------------------------

IsPlayerThere   MACRO ActorPtr, Dir
		invoke _IsPlayerThere, ActorPtr, Dir
		ENDM

_IsPlayerThere  PROTO NEAR PASCAL  ActorPtr:WORD, Dir:BYTE
_IsPlayerThere  PROC NEAR PASCAL, ActorPtr:WORD, Dir:BYTE

		push bx
		push cx
		push dx
		push es
		push si
		set es, LIBRAIRY
		mov si, ActorPtr
		xor bx,bx               ; ImaPtr
		mov cx, word ptr es:[si+ScrIma]
		jcxz ImaZ
NxPtr:          mov bx,es:[bx]
		loop NxPtr
ImaZ:
		mov ax,es:[si+ScrX]             ; al=CX, ah=CY
		mov cl,es:[bx+ImaLen]           ; cl=CL, ch=CH
		mov ch,es:[bx+ImaHei]

		ifedo Dir,EnHaut, _Haut
		ifedo Dir,EnBas,  _Bas
		ifedo Dir,AGauche, _Gauche
		ifedo Dir,ADroite, _Droite
		ifedo Dir,OnSite, _OnSite

		; change l'intervale en fonction d'un déplacement
		; en HAUT
_Haut:          dec ah                  ; y=y-1
		mov ch,1                ; h=1
		jmp MakeBite

		; en BAS
_Bas:           add ah,ch
		mov ch,1
		jmp MakeBite

		; à GAUCHE
_Gauche:        dec al
		mov cl,1
		jmp MakeBite

		; à DROITE
_Droite:        add al,cl
		mov cl,1

_OnSite:
MakeBite:
		mov si, word ptr PlyPtr
		mov dx, es:[si+ScrX]            ; dl=PX, dh=PY

		; Condition 1
		; CX + CL > PX
		; CX < PX + 2
		add al,cl
		cmp al,dl
		jbe NotThere

		sub al,cl
		add dl,2
		cmp al,dl
		jae NotThere

		add ah,ch
		cmp ah,dh
		jbe NotThere

		sub ah,ch
		add dh,2
		cmp ah,dh
		jae NotThere

		mov al,Vrai
		jmp Bye
NotThere:       mov al,Faux
bye:
		pop si
		pop es
		pop dx
		pop cx
		pop bx
		ret
_IsPlayerThere  ENDP

;----------------------------------------------------------------
; _IsUnderWater:
; Cette fonction vérifie si l'acteur est sous l'eau.
;
; Paramètre d'entré
; ActorPtr = PTR sur un acteur
;
; Paramètre de sortie
; AL= VRAI OU FAUX
;----------------------------------------------------------------
IsUnderWater    MACRO ActorPtr
		invoke _IsUnderWater, ActorPtr
		ENDM

_IsUnderWater   PROTO NEAR PASCAL  ActorPtr:WORD
_IsUnderWater   PROC NEAR PASCAL, ActorPtr:WORD
		push cx
		push es
		push si
		set es, LIBRAIRY
		mov si,ActorPtr

		mov cx,2
		mov si, word ptr es:[si+ScrX]

		mov al, Faux
Nx:             actife byte ptr [si],BottomWater, <mov al,Vrai>
		inc si
		loop Nx

		pop si
		pop es
		pop cx
		ret
_IsUnderWater   ENDP

;----------------------------------------------------------------
;----------------------------------------------------------------------
; _BitePlayer: Acquière à une requête faire par une créature, de mordre
;              le joueur.
;
; Syntaxe      BitePlayer ActPtr, Dir
;
;-------------------------------------------------------------------------
BitePlayer      MACRO ActorPtr, Dir, Drain
		invoke _BitePlayer, ActorPtr, Dir, Drain
		ENDM

_BitePlayer     PROTO NEAR PASCAL  ActorPtr:WORD, Dir:BYTE, Drain:BYTE
_BitePlayer     PROC NEAR PASCAL, ActorPtr:WORD, Dir:BYTE, Drain:BYTE
		push bx
		push cx
		push dx
		push si

		mov dx,LIBRAIRY
		mov es,dx
		mov si, ActorPtr

		mov cx,es:[si+ScrIma]
		xor bx,bx
		jcxz ImaZ
NxIma:          mov bx,es:[bx]
		loop NxIma
ImaZ:

		; ******
		mov ax,es:[si+ScrX]             ; al=CX, ah=CY
		mov cl,es:[bx+ImaLen]           ; cl=CL, ch=CH
		mov ch,es:[bx+ImaHei]

		ifedo Dir,EnHaut, _Haut
		ifedo Dir,EnBas,  _Bas
		ifedo Dir,AGauche, _Gauche
		ifedo Dir,ADroite, _Droite
		ifedo Dir,OnSite, _OnSite

		; change l'intervale en fonction d'un déplacement
		; en HAUT
_Haut:          dec ah                  ; y=y-1
		mov ch,1                ; h=1
		jmp MakeBite

		; en BAS
_Bas:           add ah,ch
		mov ch,1
		jmp MakeBite

		; à GAUCHE
_Gauche:        dec al
		mov cl,1
		jmp MakeBite

		; à DROITE
_Droite:        add al,cl
		mov cl,1

_OnSite:
MakeBite:
		mov si, word ptr PlyPtr
		mov dx, es:[si+ScrX]            ; dl=PX, dh=PY

		; Condition 1
		; CX + CL > PX
		; CX < PX + 2
		add al,cl
		cmp al,dl
		jbe NoBite

		sub al,cl
		add dl,2
		cmp al,dl
		jae NoBite

		add ah,ch
		cmp ah,dh
		jbe NoBite

		sub ah,ch
		add dh,2
		cmp ah,dh
		jae NoBite

		;*********

		mov al,Drain
		cmp al,byte ptr PlyBite
		jbe NoBite
		mov byte ptr PlyBite,al
NoBite:
		pop si
		pop dx
		pop cx
		pop bx
		ret
_BitePlayer     ENDP

;----------------------------------------------------------------------
; _IncLifeForce : Cette fonction décremente la force de vie
;                 du joueur.
;
; Paramètres d'entrées:
; Qte : La quantité à ajouter.
;----------------------------------------------------------------------

IncLifeForce    MACRO Qte
		invoke _IncLifeForce, Qte
		ENDM

_IncLifeForce   PROTO NEAR PASCAL  Qte:WORD
_IncLifeForce   PROC NEAR PASCAL, Qte:WORD
		pushall
		mov ax, word ptr PlyLifeForce
		add ax, Qte
		cmp ax, MaxLifeForce
		jb Bye

		mov ax, MaxLifeForce

Bye:            mov word ptr PlyLifeForce,ax


		popall
		ret
_IncLifeForce   ENDP

;----------------------------------------------------------------------
; _DecLifeForce : Cette fonction décremente la force de vie
;                 du joueur.
;
; Paramètres d'entrées:
; Qte : La quantité à retirer.
;----------------------------------------------------------------------

DecLifeForce    MACRO Qte
		invoke _DecLifeForce, Qte
		ENDM

_DecLifeForce   PROTO NEAR PASCAL  Qte:WORD
_DecLifeForce   PROC NEAR PASCAL, Qte:WORD

		pushall

		mov ax, word ptr PlyLifeForce
		sub ax, Qte
		cmp ax, word ptr PlyLifeForce
		jb Bye

		xor ax,ax

Bye:            mov word ptr PlyLifeForce,ax
		popall
		ret

_DecLifeForce   ENDP

;----------------------------------------------------------------------
; _CanWalk: Verifie si un acteur donné, à la posibilité de se déplacer
;           dans une direction donnée.
;
; Paramètres d'entrées:
; ActorPtr: un PTR sur l'acteur désiré
; En sortie:
; AL = 0 si faux; AL=1 si vrai
;-------------------------------------------------------------------------
CanWalk         MACRO ActorPtr, Dir
		invoke _CanWalk, ActorPtr, Dir
		ENDM

_CanWalk        PROTO NEAR PASCAL  ActorPtr:WORD, Dir:BYTE
_CanWalk        PROC NEAR PASCAL, ActorPtr:WORD, Dir:BYTE
Local           Largeur:word
Local           Hauteur:word
Local           Xpos:word
Local           Ypos:word
Local           ActClass:byte

		push bx
		push cx
		push dx
		push si

		mov Largeur,0
		mov Hauteur,0

		mov dx,LIBRAIRY
		mov es,dx

		mov si,ActorPtr
		movb ActClass, byte ptr es:[si+ScrStat]
		mov ax,word ptr es:[si+ScrX]            ; al = Xpos
							; ah = Ypos
		mov cx,word ptr es:[si+ScrIma]          ; CX = NoIma
		xor bx,bx                               ; BX = PTR ima defs
		jcxz ImaNoZ
NxImaNo:        mov bx,es:[bx]
		loop NxImaNo
ImaNoZ:

		mov dl, byte ptr es:[bx+ImaLen]
		mov dh, byte ptr es:[bx+ImaHei]

		ifedo Dir, SautAGauche, _SautGauche
		ifedo Dir, SautADroite, _SautDroite

		.if (PlyJumpFlag !=0) && (ActClass==Player)
		;ifedo byte ptr PlyJumpFlag, 0, NormalGamePlay
			ifedo Dir,AGauche,_Gauche
			ifedo Dir,ADroite,_Droite
		.endif

NormalGamePlay: ifedo Dir,EnHaut,Haut
		ifedo Dir,EnBas,Bas
		ifedo Dir,AGauche,Gauche
		ifedo Dir,ADroite,Droite
		ifedo Dir,SautAGauche, SautGauche
		ifedo Dir,SautADroite, SautDroite

		;----------------------


_SautDroite:    add al,dl                       ; x = x + l
		;dec ah                         ; y = y - 1
		mov dl,1                        ; l = 1
		mov dh,1
		jmp Verifier

_SautGauche:    dec al                          ; x = x - 1
		;dec ah                         ; y = y - 1
		mov dl,1                        ; l = 1
		mov dh,1
		jmp Verifier

_Gauche:        dec al                          ; x =x -1
		inc ah
		mov dl,1                        ; l = 1
		mov dh,1
		jmp Verifier

_Droite:        add al,dl                       ; x =x +l
		mov dl,1                        ; l =1
		mov dh,1
		inc ah
		jmp Verifier

Haut:           ;ifedo ah,0,Non                 ; Avancer vers le haut?
		.if byte ptr ah==0
			jmp Non
		.endif
		dec ah
		mov dh,1                        ; Hauteur = 1
		jmp Verifier

Bas:            add ah,dh
		;inc ah                         ; Avancer vers le bas?

		mov dh,1                        ; Hauteur = 1
		jmp Verifier

Gauche:         ;ifedo al,0,Non                 ; Avancer vers la gauche?
		dec al
		mov dl,1                        ; Largeur = 1
		jmp Verifier

Droite:         add al,dl
		;inc al                         ; Avancer vers la droite?
		mov dl,1                        ; Largeur = 1
		jmp Verifier

SautGauche:     dec al                          ; Sauter à gauche
		dec ah
		mov dl,1
		jmp Verifier

SautDroite:     add al,dl                       ; Sauter à droite
		dec ah
		mov dl,1
		jmp Verifier

		;-----------------------

Verifier:       mov byte ptr Largeur,dl
		mov byte ptr Hauteur,dh
		mov byte ptr Xpos, al
		mov byte ptr YPos,ah
		mov si,ax                       ; SI = Ptr to

LOOP2:
		mov dl, byte ptr Largeur

LOOP1:
		mov al,[si]
		mov ah,ActClass
		ifedo ah, Player, _Player

		ifedo al, StopClass, Non

		ifedo ah, Fish , _Fish
		ifedo al, TopWater, Non
		ifedo al, BottomWater,Non

_Fish:          cmp al,0e0h
		jae Non
_Player:        cmp al,0e0h
		jb _Knock
		cmp al,0f0h
		jae _Knock
		jb Non

_Knock:

		cmp al,Player
		je Non
		cmp al,0c0h             ; Gestion des
		jb _Parfait             ; classes C0 à CF.
		cmp al,0d0h
		jae _Parfait
		ifedo al,VampirePlant,_Parfait
		jb Non
_Parfait:
		inc si
		dec dl
		or dl,dl
		jne LOOP1

		sub si,Largeur
		add si,256
		dec dh
		or dh,dh
		jne LOOP2
		; CanWalk -- Deuxième partie...

		mov si,ChgingDefs ; modification 5 mai 1995
NxScr:          cmp word ptr es:[si],-1
		je LastScrDef

		mov al,es:[si+ScrStat]
		cmp al,Player
		je IsObst
		cmp al,0c0h
		jb XObst
		cmp al,0d0h
		jae XObst



IsObst:
		mov al,byte ptr XPos      ; al=X; ah=Y
		mov ah,byte ptr YPos

		mov bx,0
		mov cx,word ptr es:[si+ScrIma]
		jcxz ImaZ
NxIma:          mov bx,es:[bx]
		loop NxIma
ImaZ:
		mov dl,byte ptr es:[bx+2]
		mov dh,byte ptr es:[bx+4]
		mov cx,es:[si+ScrX]

		add cl,dl                       ; Première condition
		cmp cl,al                       ; ax+al >= bx
		jbe NotInContact

		sub cl,dl                       ; Deuxième condition
		add al,byte ptr Largeur         ; ax <= bx + bl
		cmp cl,al
		jae NotInContact

		add ch,dh
		cmp ch,ah
		jbe NotInContact

		sub ch,dh
		add ah, byte ptr Hauteur
		cmp ch,ah
		jae NotInContact
		jb Non

NotInContact:
XObst:          add si,8
		jmp NxScr
LastScrDef:
		jmp Oui

Non:            mov al,0
		jmp Bye
Oui:            mov al,1
Bye:            pop si
		pop dx
		pop cx
		pop bx
		ret
_CanWalk        ENDP



;------------------------------------------------------------------------
; _RemoveAct:
; retire un acteur de l'écran. En effect la procédure efface l'acteur
; de l'écran, s'il est visible.
;
; RemoveAct ActPtr
;-------------------------------------------------------------------------
RemoveActor     MACRO ActorPtr
		invoke _RemoveAct, ActorPtr
		ENDM

_RemoveAct      PROTO NEAR PASCAL  ActorPtr:WORD
_RemoveAct      PROC NEAR PASCAL, ActorPtr:WORD
		pushall
		set es,LIBRAIRY
		set fs,SCREEN
		set gs,0a000h

		mov si,ActorPtr
		xor bx,bx
		mov cx,word ptr es:[si+ScrIma]
		jcxz ImaZ
NxIma:          mov bx,word ptr es:[bx]
		loop NxIma
ImaZ:

		; Condition 1
		; ActX + ActL > Mx
		; ActX <Mx + ScrLen

		mov cx,word ptr MX
		mov ax, es:[si+ScrX]

		add al, es:[bx+2]
		cmp al,cl
		jb NotVisible

		sub al, es:[bx+2]
		add cl,byte ptr ScrLen
		cmp al,cl
		ja NotVisible

		add ah, es:[bx+4]
		cmp ah,ch
		jb NotVisible

		sub ah,es:[bx+4]
		add ch,byte ptr ScrHei
		cmp ah,ch
		ja NotVisible

		sub ax,word ptr MX
		mov ch,es:[bx+4]
LOOP3:          mov cl,es:[bx+2]
LOOP2:

		cmp al,byte ptr ScrLen
		jae NoDraw
		cmp ah,byte ptr ScrHei
		jae NoDraw

		push ax
		push ax
		mov al,0ah
		mul ah
		shl ax,8
		mov di,ax

		pop ax
		mov ah,0
		shl ax,3                ; X * 8
		add di,ax
		pop ax

		mov dx,8
		push eax
LOOP1:          mov eax,fs:[di]
		mov gs:[di],eax
		mov eax,fs:[di+4]
		mov gs:[di+4],eax
		add di,140h
		dec dx
		or dx,dx
		jne LOOP1
		pop eax

NoDraw:
		inc al
		dec cl
		cmp cl,0
		jne LOOP2

		sub al,es:[bx+2]
		inc ah
		dec ch
		cmp ch,0
		jne LOOP3

NotVisible:
		popall
		ret
_RemoveAct      ENDP

;-----------------------------------------------------------------------
; StallGameInfo:
; Cette procédure sert à afficher les informations permanentes sur l'écran
; avec que l'on commence un tableau
StallGameInfo PROC
		DrawString 0,22,DATA,offset PtsTxt, -6

		.if byte ptr GameDoodle==FirstLevel
			DrawString 16,22, DATA, offset QueteTxt, -8
			TagFont 35,22,CAR_FLEUR,0
			TagFont 37,22,CAR_FLEUR,0
			TagFont 39,22,CAR_FLEUR,0
		.else
			.if DemoOn==VRAI
				DrawString 16,22, DATA, offset DemoTxt, -4
			.else
				DrawString 16,22,DATA,offset FleursTxt, -6
			.endif
		.endif

		ret
StallGameInfo ENDP

;-----------------------------------------------------------------------
; AfficherGameInfo:
; Cette procédure sert à afficher les informations relatives à l'état
; de la partie.
AfficherGameInfo PROC
Local           X:BYTE
Local           Car:BYTE
		pushall
		mov cx,8


		mov X,7
		mov si, offset PLYSCORE
		mov car,0

AGI:            mov al, [si]
		add al, CAR_0
		mov Car,al
		TagFont X,22,Car, +2
		inc X
		inc si
		loop AGI

		call AjusterFleurFrames

		.if byte ptr GameDoodle == FirstLevel || byte ptr DemoOn==VRAI
		.else
			TagFont 24,22,byte ptr NbrFleursFrame+1,+2
			TagFont 23,22,byte ptr NbrFleursFrame,+2
		.endif


		.if (byte ptr PlyBite==Faux) && (byte ptr BiteDelai==Faux)
			DrawBar word ptr PlyLifeForce,2, 23
		.else
			DrawBar word ptr PlyLifeForce,4, 23
		.endif

		DrawBar word ptr PlyOxygen,15, 24
		;pause 100
		popall
		ret
AfficherGameInfo ENDP

;-------------------------------------------------------------------------
AddToScore      MACRO Pts
		invoke _AddToScore, Pts
		ENDM

_AddToScore     PROTO NEAR PASCAL  Pts:BYTE
_AddToScore     PROC NEAR PASCAL, Pts:BYTE
		push si

		mov si, offset PlyScore+7
		addb [si], Pts

ChkNx:          cmp byte ptr [si],10
		jb Bye
		sub byte ptr [si],10
		inc byte ptr [si-1]
		dec si
		jmp ChkNx

Bye:            cmp si, offset PlyScore+7
		je Bye_
		mov si,offset PlyScore+7
		jmp ChkNx
Bye_:
		pop si
		ret
_AddToScore     ENDP

;-------------------------------------------------------------------------
Grab            MACRO ObjPtr, Pts
		invoke _Grab, ObjPtr, Pts
		ENDM

_Grab           PROTO NEAR PASCAL  ObjPtr:WORD,Pts:WORD
_Grab           PROC NEAR PASCAL, ObjPtr:WORD,Pts:WORD
		push ax
		push si
		set es,LIBRAIRY

		mov si,ObjPtr
		RemoveActor si

		mov ax, word ptr _PtsFrame
		add ax, Pts
		mov es:[si+ScrIma], ax

		mov byte ptr es:[si+ScrStat],0
		mov byte ptr es:[si+ScrU2],1
		dec byte ptr es:[si+ScrX]
		dec byte ptr es:[si+ScrY]

		drawentry si
		drawentry word ptr PlyPtr

		pop si
		pop ax
		ret
_Grab           ENDP

;-------------------------------------------------------------------------
; LA FONCTION _IsFalling:
; Entrée:
; ActPtr = Ptr sur un acteur
; Sortie:
; VRAI AL = 1, FAUX AL = 0
; NOTE: AH peut-être modifié
;--------------------------------------------------------------------------

IsFalling       MACRO ActPtr
		invoke _IsFalling,ActPtr
		ENDM

_IsFalling      PROTO NEAR PASCAL  ActPtr:WORD
_IsFalling      PROC NEAR PASCAL, ActPtr:WORD
Local           ActorClass: BYTE
		push bx
		push cx
		push dx
		push si

		set es,LIBRAIRY

		mov si,ActPtr
		movb byte ptr ActorClass, es:[si+ScrStat]

		mov al,byte ptr es:[si+ScrX]
		mov ah,byte ptr es:[si+ScrY]

		xor bx,bx                               ; Obtenir un PTR
		mov cx, word ptr es:[si+ScrIma]         ; sur l'image
		jcxz ImaZ                               ; associé à l'obj.
NxIma:          mov bx,word ptr es:[bx]
		loop NxIma
ImaZ:

		mov si,ax                               ; Ptr
							; sur la MAP

		mov ah,1

		mov ch,byte ptr es:[bx+ImaHei]
		inc ch
		mov dl,ch

LOOP2:          mov cl,byte ptr es:[bx+ImaLen]

LOOP1:
		mov al,[si]
		cmp al,TopWater
		jne NOT_TopWater
		ifndo ch,dl,StillFall

NOT_TopWater:
		cmp al,Ladder
		jb StillFall


		.if ch==1
		     .if al>=StopClass
			 jmp StillFall
		     .endif

		.else
		     .if al>= ObstacleClass
			 jmp StillFall
		     .endif
		.endif

		;cmp al,StopClass
		;cmp al,ObstacleClass
		;jae StillFall
		xor ah,ah

StillFall:      inc si
		dec cl
		or cl,cl
		jne LOOP1

		sub si,word ptr es:[bx+ImaLen]
		add si,256
		dec ch
		or ch,ch
		jne LOOP2

		mov al,ah

		pop si
		pop dx
		pop cx
		pop bx
		ret

_IsFalling      ENDP
;-------------------------------------------------------------------------
; Branche sur la destionation si le joueur est au milieu, autrement
; l'exécution se poursuit normalement.
EstAuMilieu     MACRO Dest
Local Bye
		set es,LIBRAIRY
		mov si,word ptr PlyPtr
		mov al,byte ptr es:[si+ScrX]
		sub al,byte ptr MX
		cmp al,(MaxColonnes/2)-1
		jae Bye
		call SlowDown
		copyseg SCREEN,SCREEN
		jmp Dest

Bye:
		ENDM


IsMid           MACRO
Local Bye, Bye2
		push si
		set es,LIBRAIRY
		mov si,word ptr PlyPtr
		mov al,byte ptr es:[si+ScrX]
		sub al,byte ptr MX
		cmp al,(MaxColonnes/2)-1
		jae Bye
		call SlowDown
		copyseg SCREEN,SCREEN
		mov al,0
		jmp Bye2
Bye:            mov al,1
Bye2:           pop si
		ENDM


IfScrollLf      MACRO
Local Delai,Bye
		ifedo byte ptr MX,0, Delai
		call ScrollLf
		dec byte ptr MX
		call DessinerBck
		jmp bye

Delai:          call SlowDown
		RemoveActor word ptr PlyPtr
		copyseg SCREEN,SCREEN
Bye:
		ENDM


IfDrawBck       MACRO
Local           Bye, MX_IS_Z
		ifedo byte ptr MX,0,MX_IS_Z
		call DessinerBck
		jmp Bye
MX_IS_Z:        RemoveActor word ptr PlyPtr

Bye:
		ENDM

;-------------------------------------------------------------------------
; _MapLevelExtensionProc est là pour corriger la petite erreur qui s'est
; glissée dans la conception des classes conteneurs des différentes
; catégories d'objets.

; Si un objet de classe 0xDD est superposée à un autre de 0xDE ou 0xDF,
; le nouvel objet sera ignoré au profit des autres objs de numéro
; supérieur. Ceci s'est produit puisque la catégorie 0xDD a été rajouté
; par la suite et par conséquent, n'était pas prévue au moment de
; l'établissement de la procédure MapLevelExtensionProc.

_MapLevelExtensionProc  PROC

		ifndo byte ptr es:[si+1], Sand, XSand
		movb byte ptr [di], byte ptr es:[si+1]
XSand:

		ret
_MapLevelExtensionProc  ENDP


;--------------------------------------------------------------------
; MakeMove:
; Ajuste la position d'un acteur en fonction d'un déplacement
; éffectué dans une direction donnée
;--------------------------------------------------------------------
MakeMove        MACRO ActorPtr, Dir
		invoke _MakeMove,ActorPtr, Dir
		ENDM

_MakeMove       PROTO NEAR PASCAL  ActorPtr:WORD, Dir:BYTE
_MakeMove       PROC NEAR PASCAL, ActorPtr:WORD, Dir:BYTE

		push es
		push si

		set es,LIBRAIRY
		mov si, ActorPtr

		.if Dir==EnHaut
			dec byte ptr es:[si+ScrY]
		.endif

		.if Dir==EnBas
			inc byte ptr es:[si+ScrY]
		.endif

		.if Dir==AGauche
			dec byte ptr es:[si+ScrX]
		.endif

		.if Dir==ADroite
			inc byte ptr es:[si+ScrX]
		.endif

		.if Dir==SautAGauche
			dec byte ptr es:[si+ScrY]
			dec byte ptr es:[si+ScrX]
		.endif

		.if Dir==SautADroite
			dec byte ptr es:[si+ScrY]
			inc byte ptr es:[si+ScrX]
		.endif


Bye:
		pop si
		pop es
		ret


_MakeMove       ENDP


MayFall        MACRO ActorPtr
		invoke _MayFall,ActorPtr
		ENDM

_MayFall       PROTO NEAR PASCAL  ActorPtr:WORD
_MayFall       PROC NEAR PASCAL, ActorPtr:WORD
		isFalling si
		.if TRUE
		     CanWalk si, EnBas
		.endif
		ret

_MayFall        ENDP





;--------------------------------------------------------------------
; _TestAim: Vérifie si une créature est capable peut se déplacer dans
;           une direction donnée.
; Paramètres d'entrés:
; ActorPtr      : Ptr sur l'acteur désiré
; Dir           : Direction
; Paramètre de sorties:
; al = 0 Ne peut traverser
; al = 1 Peut traverser
;--------------------------------------------------------------------
TestAim         MACRO ActorPtr, Dir
		invoke _TestAim,ActorPtr, Dir
		ENDM

_TestAim        PROTO NEAR PASCAL  ActorPtr:WORD, Dir:BYTE
_TestAim        PROC NEAR PASCAL, ActorPtr:WORD, Dir:BYTE

		push si
		set es,LIBRAIRY
		mov si,ActorPtr

		CanWalk ActorPtr, Dir
		ifzdo al,Bye

		ifedo dir,EnHaut,  _EnHaut
		ifedo dir,EnBas,   _EnBas
		ifedo dir,AGauche, _AGauche
		ifedo dir,ADroite, _ADroite


_EnHaut:        CanWalk si, EnHaut
		ifzdo al,Bye

		.if byte ptr es:[si+ScrY]!=0
			dec byte ptr es:[si+ScrY]
			IsFalling si
			;MayFall si
			ifedo al,Faux, MoveOn
			inc byte ptr es:[si+ScrY]
		.endif
		mov al,0
		jmp Bye


_EnBas:         CanWalk si, EnBas
		ifzdo al,Bye

		inc byte ptr es:[si+ScrY]
		IsFalling si
		;MayFall si
		ifedo al,Faux, MoveOn
		dec byte ptr es:[si+ScrY]
		mov al,0
		jmp Bye


_AGauche:       CanWalk si, AGauche
		ifzdo al,Bye

		.if byte ptr es:[si+ScrX] !=0
			dec byte ptr es:[si+ScrX]
			IsFalling si
			;MayFall si
			ifedo al,Faux, MoveOn
			inc byte ptr es:[si+ScrX]
		.endif
		mov al,0
		jmp Bye

_ADroite:       CanWalk si, ADroite
		ifzdo al,Bye

		inc byte ptr es:[si+ScrX]
		IsFalling si
		;MayFall si
		ifedo al,Faux, MoveOn
		dec byte ptr es:[si+ScrX]
		mov al,0
		jmp Bye

MoveOn:         mov al,1
Bye:
		pop si
		ret

_TestAim        ENDP

;-------------------------------------------------------------------------
; _DoPickup: this fonction will take care of picking the up
;            pickels. So they will be easier to shallow.
; Input params:
; ScriptFrame:  offset of script
; Output:
; none
;--------------------------------------------------------------------------

DoPickup        MACRO ScriptFrame
		invoke _DoPickup, ScriptFrame
		ENDM

_DoPickup       PROTO NEAR PASCAL  ScriptFrame:WORD
_DoPickup       PROC NEAR PASCAL, ScriptFrame:WORD
		pushall
		set es,LIBRAIRY
		mov si,ScriptFrame
		mov al,es:[si+ScrAtt]
		ifedo al,task_remove, RemoveSys
		ifedo al,task_source, TransSys
		ifedo al,task_change, ChangeSys
		ifedo al,task_messager, MessagerSys
		jne Bye

		;---------------------------------------------------
		; Remove a serie of OBJs of with a given U1.
RemoveSys:      mov al,es:[si+ScrU1]
		mov si,offset ScrDefs
NxRS:           ifedo word ptr es:[si],-1, UpDateScreen
		ifndo es:[si+ScrU1], al, RsN
		mov byte ptr es:[si+ScrAtt],0
		mov byte ptr es:[si+scrStat],0
		mov byte ptr es:[si+ScrU1],0
		movw word ptr es:[si+ScrIma], word ptr BlankFrame
RsN:
		add si,8
		jmp NxRS

		;-------------------------------------------------
		; Change the att of serie of OBJs with a giver U1.
ChangeSys:      mov al,es:[si+ScrU1]
		mov bl, es:[si+ScrU2]
		xor bh,bh
		mov si,offset ScrDefs
NxCS:           ifedo word ptr es:[si], -1, UpDateScreen
		ifndo es:[si+ScrU1], al, Csn
		mov byte ptr es:[si+ScrAtt],0
		mov byte ptr es:[si+ScrStat], obstacleClass
		mov byte ptr es:[si+ScrU1],0
		mov byte ptr es:[si+ScrU2],0
		mov word ptr es:[si+ScrIma], bx
Csn:            add si,8
		jmp NxCs

MessagerSys:    DrawMsg word ptr es:[si+ScrU1], (MaxLignes /2)
		pause 5000
		jmp UpdateScreen

		;----------------------------------------------
		; Transport the player to a given destination
TransSys:       mov al,byte ptr es:[si+scrU1]
		mov si, ChgingDefs
NxTCS:          ifedo word ptr es:[si], -1, TransErr
		actife byte ptr es:[si+scrAtt], task_dest, <ifedo al, es:[si+ScrU1], FDest>
		add si,8
		jmp NxTCs
FDest:


		mov al, byte ptr es:[si+scrX]
		mov ah, byte ptr es:[si+ScrY]

		mov bx, word ptr PlyPtr
		mov byte ptr es:[bx+ScrX],al
		mov byte ptr es:[bx+ScrY],ah

		sub al,9
		sub ah,9
		mov word ptr MX,ax
		jmp UpDateScreen

TransErr:       mov dx,offset TransErrtxt
		jmp SendErrorMessage

UpdateScreen:
		call DessinerEcran
		call StallGameInfo
		call AfficherGameInfo
		call MapLevel
Bye:            popall
		ret
_DoPickup       ENDP

;----------------------------------------------------------------
; _OnLadder:
; Cette fonction vérifie si l'acteur est ou pas sur une échelle.
;
; ENTRÉE
; ActorPtr : near PTR sur l'acteur
; SORTIE
; al= VRAI ou FAUX
;----------------------------------------------------------------

OnLadder        MACRO ActorPtr
		invoke _OnLadder, ActorPtr
		ENDM

_OnLadder      PROTO NEAR PASCAL  ActorPtr:WORD
_OnLadder      PROC NEAR PASCAL, ActorPtr:WORD

		push bx
		push es
		push si

		set es, LIBRAIRY
		mov si, ActorPtr

		FindImaPtr                      ; BX = ImaPtr
		mov si, es:[si+ScrX]            ; SI = MapPtr


		mov ch, es:[bx+ImaHei]
		mov al,FAUX
		xor ah,ah
		.while ch!=0
			mov cl, es:[bx+ImaLen]

			.while cl!=0
				.if (byte ptr [si] == Ladder)
					mov al,VRAI
					inc ah
				.endif
				inc si
				dec cl
			.endw

			sub si, es:[bx+ImaLen]
			dec ch
		.endw

		pop si
		pop es
		pop bx

		ret
_OnLadder      ENDP

;-------------------------------------------------------------------------
; _WillFall:
; Cette fonction vérifie si l'acteur va tomber
;
; ENTRÉE
; ActorPtr : near PTR sur l'acteur
; Dir      : une direction
; SORTIE
; al= VRAI ou FAUX
;----------------------------------------------------------------

WillFall        MACRO ActorPtr, DIr
		invoke _WillFall, ActorPtr, Dir
		ENDM

_WillFall      PROTO NEAR PASCAL  ActorPtr:WORD, Dir:BYTE
_WillFall      PROC NEAR PASCAL, ActorPtr:WORD, Dir:BYTE

		push bx
		push es
		push si
		set es,LIBRAIRY
		mov si, ActorPtr
		push dword ptr es:[si]
		push dword ptr es:[si+4]

		.if dir== EnHaut
			dec byte ptr es:[si+ScrY]
		     ; Maudit échelle...
		     .if byte ptr es:[si+ScrStat]==VCrea
			 dec byte ptr es:[si+ScrX]
			 movw word ptr es:[si+ScrIma], word ptr BlankFrame
		     .endif
		.endif

		.if dir== EnBas
		     .if byte ptr es:[si+ScrStat]==VCrea
			 FindImaPtr
			 mov al, byte ptr es:[bx+ImaLen]
			 add al, byte ptr es:[si+ScrX]
			 mov es:[si+ScrX],al
			 movw word ptr es:[si+ScrIma], word ptr BlankFrame
			inc byte ptr es:[si+ScrY]
		     .else
			inc byte ptr es:[si+ScrY]
		     .endif
		.endif

		.if dir== AGauche
		     dec byte ptr es:[si+ScrX]

		     ; Maudit échelle...
		     .if byte ptr es:[si+ScrStat]==VCrea
			 movw word ptr es:[si+ScrIma], word ptr BlankFrame
		     .endif

		.endif

		.if dir== ADroite
		     .if byte ptr es:[si+ScrStat]==VCrea
			 FindImaPtr
			 mov al, byte ptr es:[bx+ImaLen]
			 add al, byte ptr es:[si+ScrX]
			 mov es:[si+ScrX],al
			 movw word ptr es:[si+ScrIma], word ptr BlankFrame
		     .else
			 inc byte ptr es:[si+ScrX]
		     .endif
		.endif

		IsFalling si
		mov dl,al
		CanWalk si, Dir
		xor al,al
		and dl,al

		pop dword ptr es:[si+4]
		pop dword ptr es:[si]


		pop si
		pop es
		pop bx
		ret

_WillFall       ENDP

;-------------------------------------------------------------------------
; LucasUndraw:
; cette procédure sert à effacer l'écran comme LucasFilm effaçait l'écran
; dans Maniac Mansion.
;-------------------------------------------------------------------------
LucasUndraw PROC
Local           X: BYTE
Local           Y: BYTE
Local           LineSize: WORD
Local           RowSize : WORD
		pusha

		mov x, 0
		mov y, 0

		mov al,byte ptr ScrLen
		mov ah,0
		mov LineSize,ax

		mov al,byte ptr ScrHei
		mov ah,0
		mov RowSize,ax

		movb y,byte ptr RowSize
		dec y
		mov cx,RowSize
L6:             TagFont x,y,0,0
		dec y
		loop L6

		mov dx,12
L5:             mov cx, LineSize
L1:             TagFont x,y,0,0
		inc x
		loop L1

		mov cx,RowSize
		jcxz XL2
L2:             TagFont x,y,0,0
		inc y
		loop L2
XL2:
		actifn word ptr LineSize,0, <dec LineSize>
		;dec LineSize

		mov cx,LineSize
L3:             TagFont x,y,0,0
		dec x
		loop L3

		actifn word ptr RowSize,0, <dec RowSize>
		actifn word ptr LineSize,0, <dec LineSize>

		mov cx,RowSize
		jcxz XL4
L4:             TagFont x,y,0,0
		dec y
		loop L4
XL4:

		actifn word ptr RowSize,0, <dec RowSize>

		pause 20
		mov cx,dx
		dec dx
		eloop L5

		popa
		ret

LucasUndraw ENDP

;-------------------------------------------------------------------------


;-----------------------------------------------------------------------
; PauseGame:
; Cette procédure sert à pauser la partie pendant que l'on joue un partie.
; La procédure attend que l'on pèse "ESPACE" avant de continuer l'exécution
; du programme.
;-----------------------------------------------------------------------
PauseGame PROC

		DrawMsg 3, 10

		call getax
		.while al!=" "
			call getax
		.endw

		call DessinerEcran
		call StallGameInfo
		call AfficherGameInfo
		ret
PauseGame ENDP

;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------

VLAMITS2 PROC

		call VideoSwitch

		set ds,DATA
		set es,DATA
		mov dx,offset VLAMITS2_IMA
		mov bx,offset CARS-2
		mov cx,4096
		call LoadNew

		HSetHandler HiLoadError
		set ds,DATA
		set es,DATA
		mov dx,offset HISCORES_VLA
		mov bx,offset HiScores
		mov cx,20*40
		call LoadNew

HiLoadError:    HSetHandler EHandler

		; Chargement de DEFAULT.PAL
		set ds,DATA
		set es,DATA
		mov dx,offset DEFAULT_PAL
		mov bx,offset C_Registers
		mov cx,3*256
		call LoadNEw

		; Chargement de VLAMITS2.MSG
		set ds,DATA
		set es,MSG
		mov dx,offset VLAMITS2_MSG
		mov bx,0
		mov cx, MsgsSize
		call LoadNew

                set ds,DATA
                .if SB_ACTIVE== VRAI
                	LoadVOC offset JUMP_VOC, FONT4, SND_JUMP
                	LoadVOC offset METAL_VOC, FONT4, SND_METAL
                	LoadVOC offset OUCH_VOC, FONT4, SND_OUCH
                	;LoadVOC offset TRANSP_VOC, FONT4, SND_TRANSP
                	LoadVOC offset WALK_VOC, FONT4, SND_WALK
                .endif

                set ds,DATA



ReDoIntro:
		call Intro

AnotherGame:
		call GameSys
		erasemem 0a000h, 0a00h*22, 3*0a00h
		call LucasUndraw
		.if byte ptr DemoOn==FAUX
			call HiScoreSys
		.else
			.if NoShow==FAUX
				mov byte ptr DemoOn, FAUX
				call DrawBoard
				pause 5000
				jmp ReDoIntro
			.else
				mov DemoOn, FAUX
				mov NoShow, FAUX

			.endif
		.endif

		set ds,DATA
		mov ah,41h
		mov dx,offset VLAMITS2_TMP
		int 21h

		set ds,DATA
		mov byte ptr ScrHei,MaxLignes
		mov dx,offset INTRO_IMS
		call LoadIms
		mov dx,offset INTRO_SCR
		call LoadScr

		set ds,DATA
		set es,DATA
		mov dx,offset DEFAULT_PAL
		mov bx,offset C_Registers
		mov cx,3*256
		call LoadNew

		call FillRegisters

		set ds,DATA

		call DoSelect
		call BlueFadeIn

		jmp AnotherGame

;--------------------------------------------------------

Intro PROC
		pushall
		set ds,DATA

		mov dx,offset INTRO_IMS
		call LoadIms
		mov dx,offset INTRO_SCR
		call LoadScr

		ReplaceChar MSG, 0, MsgsSize, 13, 0

		call DoIntro
		set ds,DATA
		mov byte ptr ScrLen, MAXCOLONNES
		mov byte ptr ScrHei, MAXLIGNES

		call DoSelect
		call BlueFadeIn
		CopySeg 0a000h,SCREEN

		set ds,DATA
		mov byte ptr Diff,ah
		popall
		ret

Intro    ENDP

;-----------------------------------------------------------------
DoSelect PROC

		set fs,FONT
		call AdjScreen

		mov byte ptr MX,30h
		mov byte ptr MY,0eh

		call DrawScreen
		call DrawSomeScreen

DoS1:           call DrawScreen
		CopySeg 0a000h,Screen
		set es,Librairy

		xor byte ptr AniFlag, 1
		ifedo byte ptr AniFlag,0,NoAni
		inc word ptr IAniFlag
		cmp word ptr IAniFlag,20
		jne NotTooBig
		nul word ptr IAniFlag
NotTooBig:      call AdjScreen

		mov si,offset ScrDefs +0f8h*8
		mov cx,107h-0f8h
DoS2:           mov ax, word ptr es:[si+4]
		ifedo ax,19h,Now1ah
		jne Now19h
Now1ah:         mov word ptr es:[si+4],1ah
		jmp DoS3
Now19h:         mov word ptr es:[si+4],19h

DoS3:           add si,8
		loop DoS2

NoAni:
		mov si,3*64
		mov cx,4*64
AniDiams:       mov al,fs:[si]
		or al,al
		je NulPix
		inc al
		ifedo al,5*8+1, To4x8Plus1
		jne OkFine
To4x8Plus1:     mov al,4*8+1
OkFine:         mov fs:[si],al
NulPix:         inc si
		loop AniDiams

		set ds,DATA
		call getax

		.if ax!=0
			mov SelectTimer,0
		.else
			inc SelectTimer
		.endif

		ifedo  ah,F2KEY,CarryDifLevel
		ifedo  ah,F3KEY,CarryDifLevel
		ifedo  ah,F4KEY,CarryDifLevel
		ifedo  ah,F5KEY,CarryDifLevel
		ifsedo ah,F7KEY,DecShape
		ifsedo ah,F8KEY,IncShape
		.if al==RecOnKey
			mov byte ptr RecInProgress, VRAI
		.endif

		.if (al==DemoKey) || (SelectTimer > SelectTime)
			mov SelectTimer,0
			mov byte ptr DemoOn, VRAI
			set ds,DATA
			set es,DATA
			mov dx,offset DEMO_DAT
			mov bx,offset _DAT
			mov cx,Size_DAT
			call LoadNew

			set ds,DATA
			ReplaceChar DATA, offset _DAT, Size_DAT, 13, 0
			mov word ptr NomPtr, offset Nom_DAT

			ret
		.endif

		jmp DoS1

;--------------------------------------------------------------------
CarryDifLevel:  mov byte ptr LevelOption, ah
		sub ah, F2KEY-1

		set ds,DATA

		mov word ptr NomPtr, offset Nom_DAT

		mov cl,ah
		mov ch,0

A:              Read DATA, word ptr NomPtr,DATA,offset Nom

		eloop A

B:              set ds,DATA
		set es,DATA
		mov dx,offset Nom
		mov bx,offset _DAT
		mov cx,Size_DAT
		call LoadNew

		mov cx,Size_DAT
		mov si,offset _DAT
D:
		cmp byte ptr [si],13
		jne E
		mov byte ptr [si],0
E:
		inc si
		loop D
		ret

;-------------------------------------------------------------------
		; Décrement la forme du P1 & P2
DecShape:       dec byte ptr P1Shape
		ifedo byte ptr P1Shape,-1, P1EQU8
		jmp P1EQU8_
P1EQU8:         mov byte ptr P1Shape,NbPlyTypes
P1EQU8_:

		dec byte ptr P2Shape
		ifedo byte ptr P2Shape,-1,P2EQU8
		jmp P2EQU8_
P2EQU8:         mov byte ptr P2Shape,NbPlyTypes
P2EQU8_:        jmp AdjScreen

		;-------------------------------
		; Incrémente la forme de P1 & P2
IncShape:       inc byte ptr P1Shape
		ifedo byte ptr P1Shape,NbPlyTypes+1,XP1EQU8
		jmp XP1EQU8_
XP1EQU8:        mov byte ptr P1Shape,0
XP1EQU8_:

		inc byte ptr P2Shape
		ifedo byte ptr P2Shape,NbPlyTypes+1,XP2EQU8
		jmp XP2EQU8_
XP2EQU8:        mov byte ptr P2Shape,0
XP2EQU8_:       jmp AdjScreen

;------------------------------------------------------------------

ChgNbPlys:      xor byte ptr NbJoueurs, 3
AdjScreen:      set es,LIBRAIRY
		ifedo byte ptr NbJoueurs,2, Show2Plys
		;mov word ptr es:[4+16ch*8+ScrDefs],0145h
		;mov word ptr es:[4+169h*8+ScrDefs],0h
		jmp Only2Plys

Show2Plys:      ;mov word ptr es:[4+16ah*8+ScrDefs],0146h
		;mov word ptr es:[4+169h*8+ScrDefs],013ch
Only2Plys:
		mov al,byte ptr P1Shape
		;cmp al,8
		;jae Xtra1

		mov ah,20
		mul ah
		;add ax,28h
		add ax, IntPlyBaseFrame
		add ax,word ptr IAniFlag

		mov word ptr es:[4+16ch*8+ScrDefs],ax
P1S:
		nul ax
		ifedo byte ptr NbJoueurs, 1, _1Joueur

		mov al,byte ptr P2Shape
		;cmp al,8
		;jae Xtra2

		mov ah,20
		mul ah
		add ax,162h
		;add ax,28h
		add ax,word ptr IAniFlag

_1Joueur:       ;mov word ptr es:[4+16ch*8+ScrDefs],ax
P2S:
		ret

DoSelect ENDP

;------------------------------------------------------------------

LocalFadeOut PROC

		pushall
		set gs,SCREEN
		mov si,0
		mov cx,0

Nx:             mov al,gs:[si]
		cmp al,5*8+1
		jb NI
		cmp al,5*8+2
		ja NI
		sub al,5*8+1
		add al,0feh
		mov gs:[si],al

NI:             cmp al,1*8+1
		jb Ni2
		cmp al,1*8+2
		ja Ni2
		sub al,1*8+1
		add al,0fch
		mov gs:[si],al
Ni2:
		inc si
		loop Nx

		CopySeg 0a000h,SCREEN

		mov dx,64
B:              mov cx,6
		mov si,offset Cl1
		mov bx,VlaColors
A:              mov al,byte ptr [si]
		cmp al,byte ptr [bx]
		jae Done
		inc byte ptr [si]
Done:           inc si
		inc bx
		loop A

		mov bx,EpsColors
		mov cx,6
D:              mov al,byte ptr [si]
		cmp al,byte ptr [bx]
		jae Done2
		inc byte ptr [si]
Done2:          inc si
		inc bx
		loop D

		mov bx, BkcColors
		mov si,offset Bkc
		mov cx,3
E:              mov al,byte ptr [si]
		cmp al,byte ptr [bx]
		jae Done3
		inc byte ptr [si]
Done3:          inc si
		inc bx
		loop E

		SetColor 0feh, byte ptr cl1,byte ptr cl1+1,byte ptr cl1+2
		SetColor 0ffh, byte ptr cl2,byte ptr cl2+1,byte ptr cl2+2
		SetColor 0fch, byte ptr cl3,byte ptr cl3+1,byte ptr cl3+2
		SetColor 0fdh, byte ptr cl4,byte ptr cl4+1,byte ptr cl4+2
		SetColor 001h, byte ptr Bkc,byte ptr Bkc+1,byte ptr Bkc+2

		call getax
		ifkeydo EmmExit

		mov cx,dx
		dec dx
		eloop B

		popall
		ret

EmmExit:        popall
		add sp,2

		mov si,BkcColors
		setColor 001h,[si],[si+1],[si+2]
		ret


LocalFadeOut ENDP

;------------------------------------------------------------------------

DoIntro PROC

		set ds,DATA
		mov dword ptr BkColor,01010101h

		mov byte ptr MX,5
		mov byte ptr MY,-4

		copymem DATA,offset O_Registers, DATA,offset C_Registers, 3*256

		mov byte ptr MY, -4+20
		call DrawScreen

		; ****************************************
		; 1er JUILLET 1995 -- ADD-ON
		set ds,DATA
		.if SB_ACTIVE==VRAI
			.if StatusWord!=0
				mov bx, Const_StopSample
				call CtVoiceDRV
			.endif

			LoadVOC offset Vlamits2_VOC,SCREEN2,0
			set es, SCREEN2
			mov di, 1ah
			mov bx, Const_ReadSample
			pushall
			call CTVoiceDRV
			popall
			set ds, DATA

		.endif
		; 1er JUILLET 1995...
		; *****

		setcolor 001h,0,0,0
		setcolor 0fch,0,0,0
		setcolor 0fdh,0,0,0
		setcolor 0feh,0,0,0
		setcolor 0ffh,0,0,0
		call LocalFadeOut

		mov dx,5-1
		mov si,offset Intro_Pg+2
S2:             mov cx,word ptr [si]
		add si,2
S1:             inc byte ptr MY
		call DrawScreen
		CopySeg 0a000h,SCREEN
		pause 1
		ifkeydo Ret_
		loop S1

		Pause 400
		IfKeyDo Ret_

		mov cx,dx
		dec dx
		loop S2

Ret_:           ret

DoIntro ENDP
;------------------------------------------------------------------

BlueFadeIn PROC

		pushall
		set ds,DATA
		BluePtr EQU C_Registers+3
		mov cx,64
		mov di, offset BluePtr
BF:

		cmp byte ptr [di+2],0
		je ItIsOver

		dec byte ptr [di+2]

		setcolor 001,[di],[di+1],[di+2]

		pause 20
		loop BF
ItIsOver:

		copymem DATA, offset C_Registers, DATA, offset O_Registers, 256*3
		popall
		ret

BlueFadeIn ENDP
;--------------------------------------------------------------------

DarkColors      PROC

		pushall

		set gs,SCREEN
		mov si,0
		mov cx,0

DC:
		mov al,gs:[si]
		cmp al,4*8+1
		jb DC1
		cmp al,13*8
		ja DC1
		add al,13*8+1
		mov gs:[si],al
		jmp A

DC1:
		cmp al,1*8+1
		jb A
		cmp al,2*8
		ja A
		sub al,1*8
		mov gs:[si],al
A:
		inc si
		loop DC
		popall
		ret

DarkColors      ENDP

;----------------------------------------------------------

LoadDemo PROC
		set ds,DATA

		HOpenForRead word ptr NomPtr, RecFile
		skipchar DATA, word ptr NomPtr,10

		mov dx, word ptr NomPtr
		call LoadIms
		skipchar DATA, word ptr NomPtr,10

		mov dx, word ptr NomPtr
		call LoadScr
		skipchar DATA, word ptr NomPtr,10

		ret

LoadDemo ENDP

;----------------------------------------------------------

LoadLevel PROC
		set ds,DATA
                EraseSeg LIBRAIRY
		movw word ptr OldNomPtr, word ptr NomPtr


	        .if SB_ACTIVE == VRAI  && (StatusWord ==0)
                	call SayLevelName
		.endif

		AfficherTitre 10, DATA, word ptr NomPtr
		pause 5000
		skipchar DATA, word ptr NomPtr,10

		mov dx,word ptr NomPtr
		call LoadIms
		skipchar DATA, word ptr NomPtr,10

		mov dx,word ptr NomPtr
		call LoadScr
		skipchar DATA, word ptr NomPtr,10

		ret
LoadLevel ENDP

;-----------------------------------------------------------------------
AjusterEcran    PROC
		set ds,DATA
		ret
AjusterEcran    ENDP
;----------------------------------------------------------------------
DessinerEcran   PROC


		call DrawBck
		CopySeg 0a000h,SCREEN
		call DrawFow
		ret

_2Joueurs:      ret
DessinerEcran   ENDP
;----------------------------------------------------------------------
; PlyOxyCtrl: se charge de gérer les controles d'oxygènes.
PlyOxyCtrl PROC
		pushall
		IsUnderWater word ptr PlyPtr
		ifedo al,Vrai, UnderWater_VRAI
		jne UnderWater_FAUX

Underwater_VRAI:
		ifedo word ptr WhileUnderWater, TimeForOxygenLost, OxyLost
		inc word ptr WhileUnderWater
		jne bye

OxyLost:        mov ax, word ptr PlyOxygen
		sub ax, OxygenDrain

		.if ax > word ptr PlyOxygen
			mov ax,0

			.if word ptr PlyBite<= LifeDrowning
				mov word ptr PlyBite, LifeDrowning
			.endif
		.endif

		mov word ptr PlyOxygen,ax
		call AfficherGameInfo
		jmp Bye

Underwater_FAUX:
		mov word ptr WhileUnderWater,0
		cmp word ptr PlyOxygen, QteOxygenNormal
		jae Bye
		add word ptr PlyOxygen, OxygenAdd
		call AfficherGameInfo

bye:
		popall
		ret
PlyOxyCtrl ENDP

;----------------------------------------------------------------------
; InitJoueur:
; Je dois trouver PLY1 & PLY2... Car il est nécéssaire d'ajuster
; les nouvelles variables suivantes: MX1, MX2, MY1 et MY2.
;----------------------------------------------------------------------
InitJoueur PROC

		set es,LIBRAIRY
		mov si,ChgingDefs ; modification 5 mai 1995             ; ChgingDefs
Rechercher:
		cmp byte ptr es:[si],-1
		je _FinRecherche_ERR
		cmp byte ptr es:[si+1],1
		je _FinRecherche

		add si,8
		jmp Rechercher

_FinRecherche_ERR:
		mov dx,offset RecJoueurEchec
		jmp SendErrorMessage

_FinRecherche:
		mov byte ptr es:[si+2],EnBas            ; Direction
		mov byte ptr es:[si+3],0                ;
		mov al,byte ptr P1Shape
		mov ah,20
		mul ah
		add ax,word ptr BaseActFrame
		mov word ptr PlyBaseFrame,ax
		add ax,5
		mov word ptr es:[si+4],ax               ; NoImage

		mov ax,word ptr es:[si+6]

		cmp al,7
		jae _MY_1
		xor al,al
		jmp _MY_

_MY_1:          sub al,7
_MY_:
		cmp ah,0eh
		jae _MY_2
		xor ah,ah
		jmp _MY_3

_MY_2:           sub ah,7
_MY_3:

		;ub ax,070eh
		mov word ptr MX,ax
		mov word ptr PlyPtr, si

Bye:            ret
InitJoueur      ENDP

;-----------------------------------------------------------------------
; Cette procédure sert à ajuster la frame actuelle du JOUEUR et celà
; pour permettre son animation.
;-----------------------------------------------------------------------
AdjPlyFrame PROC
		push ax
		set es,LIBRAIRY
		mov al,byte ptr PlyDir
		mov ah,5
		mul ah
		add ax,word ptr PlyBaseFrame
		add ax,word ptr PlyAFlag
		mov es:[si+ScrIma],ax
		pop ax
		ret
AdjPlyFrame ENDP

;-----------------------------------------------------------------------
; Cette procédure sert à changer tous les STOPS en BLANKS, du moins
; dans le but de les rendre invisible lors du jeu.
;-----------------------------------------------------------------------
ChangeStopsIntoBlanks PROC
		pushall
		set es,LIBRAIRY
		mov bx, 0
		mov cx, word ptr StopFrame
		jcxz ImaZ
NxIma:          mov bx, es:[bx]
		loop NxIma
ImaZ:

		mov ax, word ptr es:[bx+6]
		shr ax, 10
		shl ax, 12                     ; * 0x1000
		add ax, FONT
		set fs,ax

		mov di, word ptr es:[bx+6]
		and di,1023
		shl di,6

		mov cx, 64/4
FIll:           mov dword ptr fs:[di],0
		add di,4
		loop Fill
		popall
		ret

ChangeStopsIntoBlanks ENDP

ChangeBloquerIntoBlanks PROC
		pushall
		set es,LIBRAIRY
		mov bx, 0
		mov cx, word ptr BloquerFrame
		jcxz ImaZ
NxIma:          mov bx, es:[bx]
		loop NxIma
ImaZ:

		mov ax, word ptr es:[bx+6]
		shr ax, 10                     ; / 0x400
		shl ax, 12                     ; * 0x1000
		add ax, FONT
		set fs,ax

		mov di, word ptr es:[bx+6]
		and di,1023
		shl di,6

		mov cx, 64/4
FIll:           mov dword ptr fs:[di],0
		add di,4
		loop Fill
		popall
		ret

ChangeBloquerIntoBlanks ENDP

;-----------------------------------------------------------------------
; CreaturesModule:
; Cette procedure se charge de manipuler les créatures, de permettre leurs
; déplacements et s'assurer qu'elles soient bien animées.
;-----------------------------------------------------------------------
CreaturesModule PROC

		pushall
		set es,LIBRAIRY
		mov si,ChgingDefs        ; modification 5 mai 1995
NxScrEntry:     set ds,DATA
		cmp byte ptr es:[si],-1
		je Bye

		mov al,byte ptr es:[si+ScrStat]

		ifedo al,Fish,_Fish
		ifedo al,VampirePlant, _VampirePlant
		ifedo al,VCrea, _VCrea
		ifedo al,FlyPlat, _FlyingPlatform
		ifedo al,Cannibal, _C5_YC
		ifedo al,InManga, _InManga
		ifedo al,GreenFlea, _GreenFlea

		add si,8
		jmp NxScrEntry

		; ********************************
		; CLASS C0h-- FISHS HANDLER SYSTEM
		; ********************************
_Fish:          RemoveActor si
		ifedo byte ptr es:[si+ScrU1],FishLeft,_FishL

_FishR:         BitePlayer si, ADroite, FishDrain
		CanWalk si, ADroite
		ifedo al,Faux, _FishToL
		inc byte ptr es:[si+ScrX]
		add si,8
		jmp NxScrEntry

_FishToL:       dec byte ptr es:[si+ScrIma]
		mov byte ptr es:[si+ScrU1],FishLeft
		add si,8
		jmp NxScrEntry

_FishL:         BitePlayer si,AGauche, FishDrain
		CanWalk si,AGauche
		ifedo al,Faux,_FishToR
		dec byte ptr es:[si+ScrX]
		add si,8
		jmp NxScrEntry

_FishToR:       inc byte ptr es:[si+ScrIma]
		mov byte ptr es:[si+ScrU1],FishRight
		add si,8
		jmp NxScrEntry

		; ********************************
		; CLASS C1h-- VAMPIRE CREATURE
		; ********************************
_VCrea:
		set ds,DATA
		RemoveActor si
		BitePlayer si,EnHaut, VCreaDrain
		BitePlayer si,EnBas, VCreaDrain
		BitePlayer si,AGauche, VCreaDrain
		BitePlayer si,ADroite, VCreaDrain

		xor ah,ah
		mov al,byte ptr es:[si+ScrU2]
		sub word ptr es:[si+ScrIma],ax
		xor al,1
		add word ptr es:[si+ScrIma],ax
		mov byte ptr es:[si+ScrU2],al

		mov al,byte ptr es:[si+ScrU1]
		shl ax,2
		add ax,offset CosTable
		mov bx,ax

		mov cx,4
NxVCreaDest:

		TestAim si, byte ptr [bx]
		cmp al,Vrai
		je VCreaMove

		inc bx
		loop NxVCreaDest
		jmp VCreaXMove

VCreaMove:      mov al,byte ptr [bx]
		mov byte ptr es:[si+ScrU1], al
VCreaXMove:
		add si,8
		jmp NxScrEntry

		; ********************************
		; CLASS C2h-- VAMPIRE PLANTS HANDLER
		; ********************************
_VampirePlant:  RemoveActor si
		ifedo byte ptr es:[si+ScrU1],0, IncFrame
		dec word ptr es:[si+ScrIma]
		jmp VP_DoJob
IncFrame:       inc word ptr es:[si+ScrIma]
VP_DoJob:       xor byte ptr es:[si+ScrU1],1
		BitePlayer si, OnSite, PlantDrain
		BitePlayer si, EnHaut, PlantDrain
		BitePlayer si, AGauche, PlantDrain
		BitePlayer si, ADroite, PlantDrain
		add si,8
		jmp NxScrEntry

		; ********************************
		; CLASS C3h-- FLYING PLATFORM
		; ********************************
_FlyingPlatform:RemoveActor si

		mov al, byte ptr es:[si+ScrU1]
		ifedo al, EnHaut, _FlyPlatEnHaut
		ifedo al, EnBas, _FlyPlatEnBas
		ifedo al, AGauche, _FlyPlatAGauche
		ifedo al, ADroite, _FlyPlatADroite


		;--------------------------------------
		; Gère les déplacement de la platforme en
		; haut
_FlyPlatEnHaut: ifndo byte ptr PlyJumpFlag, 0, _FP_UP
		IsPlayerThere si, EnHaut
		ifndo al,Vrai, _FP_Up

		CanWalk PlyPtr, EnHaut
		ifedo al,FAUX, FP_CantMove
		dec byte ptr es:[si+ScrY]
		RemoveActor word ptr PlyPtr
		mov bx, word ptr PlyPtr
		dec byte ptr es:[bx+ScrY]
		.if (byte ptr MY!=0)
			call ScrollUp
			dec byte ptr MY
			call DessinerBck
		.endif

		add si,8
		jmp NxScrEntry

_FP_Up:         CanWalk si, EnHaut
		ifedo al,FAUX, FP_CantMove
		dec byte ptr es:[si+ScrY]
		add si,8
		jmp NxScrEntry

		;--------------------------------------
		; Gere les déplacements de la platforme
		; en bas.
_FlyPlatEnBas:
_FP_Dn:         CanWalk si, EnBas
		ifedo al,FAUX, FP_CantMove
		inc byte ptr es:[si+ScrY]
		add si,8
		jmp NxScrEntry


		;--------------------------------------
		; Gere les déplacements de la platforme
		; à gauche.
_FlyPlatAGauche:ifndo byte ptr PlyJumpFlag, 0, _FP_LF
		IsPlayerThere si, EnHaut
		ifndo al,Vrai, _FP_Lf

		CanWalk PlyPtr, AGauche
		ifedo al,FAUX, FP_CantMove
		CanWalk si, AGauche
		ifedo al,FAUX, FP_CantMove
		dec byte ptr es:[si+ScrX]
		RemoveActor word ptr PlyPtr
		mov bx, word ptr PlyPtr
		dec byte ptr es:[bx+ScrX]
		.if byte ptr MX!=0
			call ScrollLf
			dec byte ptr MX
			call DessinerBck
			;call DrawFow
		.endif
		add si,8
		jmp NxScrEntry

_FP_Lf:         CanWalk si, AGauche
		ifedo al,FAUX, FP_CantMove
		dec byte ptr es:[si+ScrX]
		add si,8
		jmp NxScrEntry


		;--------------------------------------
		; Gere les déplacements de la platforme
		; à droite.
_FlyPlatADroite:ifndo byte ptr PlyJumpFlag, 0, _FP_Rg
		IsPlayerThere si, EnHaut
		ifndo al,Vrai, _FP_Rg

		CanWalk PlyPtr, ADroite
		ifedo al,FAUX, FP_CantMove
		CanWalk si, ADroite
		ifedo al,FAUX, FP_CantMove
		inc byte ptr es:[si+ScrX]
		RemoveActor word ptr PlyPtr
		mov bx, word ptr PlyPtr
		inc byte ptr es:[bx+ScrX]

		call ScrollRg
		inc byte ptr MX
		call DessinerBck

		add si,8
		jmp NxScrEntry

_FP_Rg:         CanWalk si, ADroite
		ifedo al,FAUX, FP_CantMove
		inc byte ptr es:[si+ScrX]
		add si,8
		jmp NxScrEntry

		; Change l'orientation de la
		; platforme.
FP_CantMove:    xor byte ptr es:[Si+ScrU1],1
		add si,8
		jmp NxScrEntry

		; ********************************
		; CLASS C5h-- YOUNG CANIBAL
		; ********************************
_C5_YC:
		RemoveActor si
		xor bh,bh
		mov bl, byte ptr es:[si+ScrU1]
		add bx, offset CannibalDat

		xor ah,ah
		mov al,[bx]             ; al=AIM
		.if al<AGauche
		    mov al,EnHaut
		.endif

		shl ax,2                ; ax= (al=AIM) * 4
		add ax, word ptr CannibalBaseFrame
		xor dh,dh
		mov dl,byte ptr es:[si+ScrU2]
		add ax,dx
		mov es:[si+ScrIma],ax

		inc dl
		and dl,3
		mov es:[si+ScrU2],dl

		xor dh,dh
		mov dl, byte ptr es:[si+ScrU1]
		mov cx, 8

YC_NxDir:
		CanWalk si, byte ptr [bx]
		.if TRUE


		  .if byte ptr [bx]<AGauche
			TestAim si, byte ptr [bx]
			.if TRUE
			     jmp YC_Move
			.endif
		  .else
			MakeMove si, byte ptr [bx]
			jmp YC_Move
		  .endif

		.else
		     .if byte ptr [bx]>=AGauche
			mov dh, [bx]
			add dh, (SautAGauche - AGauche)
			CanWalk si, dh
			.if TRUE
			    MakeMove si, dh
			    jmp YC_MOVE
			.endif
			xor dh,dh
		     .endif
		.endif

		inc dl
		and dl,7
		mov bx,dx
		add bx, offset CannibalDAT
		loop YC_NxDir

		add si,8
		jmp NxScrEntry

YC_MOVE:        mov byte ptr es:[si+ScrU1], dl
		xor ah,ah
		mov al,[bx]             ; al=AIM
		.if al<AGauche
		    mov al,EnHaut
		.endif

		shl ax,2                ; ax= (al=AIM) * 4
		add ax, word ptr CannibalBaseFrame
		xor dh,dh
		mov dl,byte ptr es:[si+ScrU2]
		add ax,dx
		mov es:[si+ScrIma],ax

		add si,8
		jmp NxScrEntry

		; ********************************
		; CLASS C6h-- INMANGA
		; ********************************

_InManga:
		RemoveActor si

		.if byte ptr es:[si+ScrU1]< AGauche
		     mov byte ptr es:[si+ScrU1],AGauche
		.endif

		TestAim si, byte ptr es:[si+ScrU1]
		.if TRUE
		.else
		      IsPlayerThere si, byte ptr es:[si+ScrU1]
		     .if TRUE
			 mov PlyLifeForce,0
			 MakeMove si, byte ptr es:[si+ScrU1]
			 mov ax, es:[si+ScrX]
			 FindImaPtr
			 RemoveActor word ptr PlyPtr
			.if byte ptr es:[si+ScrU1] == AGauche
			   inc al
			   add ah,byte ptr es:[bx+ImaHei]
			   sub ah,2
			.else
			   add al, byte ptr es:[bx+ImaLen]
			   dec al
			   add ah,byte ptr es:[bx+ImaHei]
			   sub ah,2
			.endif

			 mov bx, word ptr PlyPtr
			 mov es:[bx+ScrX], ax
			 mov PlyLifeForce,0

		     .else
			  xor byte ptr es:[si+ScrU1],1

		     .endif
		.endif

		xor dh,dh
		mov dl,byte ptr es:[si+ScrU1]
		sub dl,AGauche
		shl dx,1                                ; dx = Aim * 2

		xor ah,ah
		mov al, byte ptr es:[si+ScrU2]          ; ax = Frame
		xor byte ptr es:[si+ScrU2],1            ;      0 à 1
		add ax,dx                               ; ax = Frame+Aim*2
		add ax, word ptr InMangaBaseFrame
		mov es:[si+ScrIma],ax

		add si,8
		jmp NxScrEntry

		; ********************************
		; CLASS CFh-- GREEN FLEA
		; ********************************

_GreenFlea:
		RemoveActor si
		BitePlayer si, OnSite, FleaDrain
		BitePlayer si, EnHaut, FleaDrain
		BitePlayer si, EnBas, FleaDrain
		BitePlayer si, AGauche, FleaDrain
		BitePlayer si, ADroite, FleaDrain

		xor bh,bh
		mov bl, byte ptr es:[si+ScrU1]
		add bx, offset CannibalDat

		xor ah,ah
		mov al,[bx]             ; al=AIM
		.if al<AGauche
		    mov al,EnHaut
		.endif

		shl ax,1                ; ax= (al=AIM) * 2
		add ax, word ptr FleaBaseFrame
		xor dh,dh
		mov dl,byte ptr es:[si+ScrU2]
		add ax,dx
		mov es:[si+ScrIma],ax

		inc dl
		and dl,1
		mov es:[si+ScrU2],dl

		xor dh,dh
		mov dl, byte ptr es:[si+ScrU1]
		mov cx, 8

GF_NxDir:
		CanWalk si, byte ptr [bx]
		.if TRUE


		  .if byte ptr [bx]<AGauche
			TestAim si, byte ptr [bx]
			.if TRUE
			     jmp GF_Move
			.endif
		  .else
			MakeMove si, byte ptr [bx]
			jmp GF_Move
		  .endif

		.else
		     .if byte ptr [bx]>=AGauche
			mov dh, [bx]
			add dh, (SautAGauche - AGauche)
			CanWalk si, dh
			.if TRUE
			    MakeMove si, dh
			    jmp GF_MOVE
			.endif
			xor dh,dh
		     .endif
		.endif

		inc dl
		and dl,3
		mov bx,dx
		add bx, offset CannibalDAT
		loop GF_NxDir

		add si,8
		jmp NxScrEntry

GF_MOVE:        mov byte ptr es:[si+ScrU1], dl
		xor ah,ah
		mov al,[bx]             ; al=AIM
		.if al<AGauche
		    mov al,EnHaut
		.endif

		shl ax,1                ; ax= (al=AIM) * 2
		add ax, word ptr FleaBaseFrame
		xor dh,dh
		mov dl,byte ptr es:[si+ScrU2]
		add ax,dx
		mov es:[si+ScrIma],ax

		add si,8
		jmp NxScrEntry

Bye:            popall
		ret

CreaturesModule ENDP

;-------------------------------------------------------------------------
; FallModulator:
; Cette procédure se charge de faire tomber les créature et les objs
; qui se trouvent dans le tableau qui est à être joué.
;-------------------------------------------------------------------------
FallModulator PROC
		pushall
		set es,LIBRAIRY
		mov si, ChgingDefs

NxFrame:        cmp word ptr es:[si],-1
		je Bye

		mov al, es:[si+ScrStat]

		.if al>= Fish && (al<Ladder)
		    IsFalling si
		    .if TRUE
			.if byte ptr GameDoodle!=2
			     CanWalk si, EnBas
			    .if TRUE
				RemoveActor si
				MakeMove si, EnBas
			   .endif
			.endif
		    .endif
		.endif

Nx:             add si,8
		jmp NxFrame
bye:            popall
		ret

FallModulator ENDP

;-------------------------------------------------------------------------
; PickUp:
; Cette procédure permet au joueur de rammasser un objet.
;-------------------------------------------------------------------------
PickUp          PROC

		pushall
		set es,LIBRAIRY

		mov si, ChgingDefs ; modification 5 mai 1995
NxObj:          cmp byte ptr es:[si],-1
		je Bye

		mov al,es:[si+ScrStat]
		ifzdo al,MaybePts
		cmp al,0c0h
		jae Ignore

		xor bx,bx
		mov cx,es:[si+ScrIma]
		jcxz ImaZ
NxIma:          mov bx,es:[bx]
		loop NxIma
ImaZ:

		mov cx, es:[si+ScrX]    ; cl= ObjX, ch=ObjY
		mov dl, byte ptr es:[bx+2]      ; dl = ObjL
		mov dh, byte ptr es:[bx+2]      ; dh = ObjH

		mov bx,word ptr PlyPtr
		mov bx, es:[bx+ScrX]    ; bl = PlyX, bh=PlyY

		; Condition #1
		; ObjX+ObjL > PlyX
		add cl,dl
		cmp cl,bl
		jbe Ignore

		; Condition #2
		; ObjX < PlyX + PlyL
		sub cl,dl
		add bl,2
		cmp cl,bl
		jae Ignore

		; Condition #3
		; ObjY+ObjH > PlyY
		add ch,dh
		cmp ch,bh
		jb Ignore

		; Condition #4
		; ObjY < PlyY + PlyH
		sub ch,dh
		add bh,2
		cmp ch,bh
		ja Ignore

		ifedo al,Oxygen, _Oxygen                ; CLASS 03h
		ifedo al,Transporter, _Transporter      ; CLASS 04h
		ifedo al,Diamant, _Diamant              ; CLASS 10h
		ifedo al,Fleur, _Fleur                  ; CLASS 11h
		ifedo al,Fruit, _Fruit                  ; CLASS 12h
		ifedo al,Mushroom, _Mushroom            ; CLASS 13h
		ifedo al,Misc, _Misc                    ; CLASS 14h
		ifedo al,DeadlyItem, _DeadlyItem        ; CLASS 15h

Ignore:         add si,8
		jmp NxObj

_DeadlyItem:
		DoPickup si
		RemoveActor si
		movw word ptr es:[si+ScrIma], BlankFrame
		mov byte ptr es:[si+ScrAtt],0
		mov byte ptr es:[si+ScrStat],0
		mov al,byte ptr es:[si+ScrU1]
		.if al > byte ptr PlyBite
			movb byte ptr PlyBite, es:[si+ScrU1]
		.else
			mov byte ptr PlyBite, NeedleDrain
		.endif

		mov byte ptr es:[si+ScrU1],0
		mov byte ptr es:[si+ScrU2],0

		call DrawFow
		call AfficherGameInfo
		jmp Ignore

_Mushroom:      jmp Ignore

_Misc:           mov ax, word ptr es:[si+ScrIma]
		.if ax==5
			AddToScore 200
			AddToScore 200
			DoPickup si
			Grab si, _400Pts
			call AfficherGameInfo
			jmp Ignore
		.endif

		.if ax==21h
			AddToScore 200
			DoPickup si
			Grab si, _200Pts
			call AfficherGameInfo
			jmp Ignore
		.else
			AddToScore 10
			DoPickup si
			Grab si, _10Pts
			call AfficherGameInfo
			jmp Ignore
		.endif

_Oxygen:        mov ax,PlyOxygen
		add ax,4
		.if (ax < PlyOxygen) || (PlyOxygen > MaxOxygen)
			mov PlyOxygen,MaxOxygen
		.else
			mov PlyOxygen, ax
		.endif

		AddToScore 10
		DoPickup si
		Grab si, _10Pts
		call AfficherGameInfo
		jmp Ignore

_Diamant:       AddToScore 50
		DoPickup si
		Grab si, _50Pts
		call AfficherGameInfo
		jmp Ignore

_Fruit:         ifedo word ptr es:[si+ScrIma],1,__15Pts
		ifedo word ptr es:[si+ScrIma],2,__10Pts
		jmp __25Pts

__15pts:        AddToScore 15
		DoPickup si
		Grab si, _15Pts
		call AfficherGameInfo
		jmp Ignore

__10Pts:        AddToScore 10
		DoPickup si
		Grab si, _10pts
		IncLifeForce 1
		call AfficherGameInfo
		jmp Ignore

__25Pts:        AddToScore 25
		DoPickup si
		Grab si, _25PTs
		call AfficherGameInfo
		jmp Ignore

_Fleur:         AddToScore 100
		DoPickup si
		Grab si, _100Pts
		call CompterFleurs
		IncLifeForce 4
		call AfficherGameInfo
		jmp Ignore

_Transporter:   DoPickup si
		jmp Ignore

Bye:            call DrawFow
		popall
		ret

		;-----------------------------------

MaybePts:       ifedo byte ptr es:[si+ScrU2],0, Ignore
		inc byte ptr es:[si+ScrU2]
		RemoveActor si
		dec byte ptr es:[si+ScrY]
		ifedo byte ptr es:[si+ScrU2],10,DelPts
		DrawEntry si
		DrawEntry word ptr PlyPtr
		jmp Ignore

DelPts:         set word ptr es:[si+ScrIma],word ptr BlankFrame
		mov byte ptr es:[si+ScrU2],0
		RemoveActor si
		jmp Ignore


PickUp          ENDP

;----------------------------------------------------------------------

DessinerBck     PROC
		pushall

		set fs,SCREEN
		set gs,0a000h
		mov di,0
		mov dx,22
DB2:            mov cx,0a00h/4
DB_:
		mov eax,fs:[di]
		mov gs:[di],eax
		add di,4
		loop DB_

		mov cx,dx
		dec dx
		loop DB2

		popall
		ret
DessinerBck     ENDP

;-------------------------------------------------------------------------
; CompterFleurs:
; Cette procédure compte le nombre du fleurs contenues dans le tableau
; et retourne cette valeur dans la variable globale NbrFleurs.
;-------------------------------------------------------------------------
CompterFleurs   PROC
		push ax
		push es
		push si
		xor ax,ax

		set es,LIBRAIRY
		mov si,ChgingDefs

NxEnr:          cmp word ptr es:[si],-1
		je Bye
		cmp byte ptr es:[si+ScrStat],Fleur
		jne PasFleur
		inc ax
PasFleur:
		add si,8
		jmp NxEnr

Bye:            mov word ptr NbrFleurs, ax
		pop si
		pop es
		pop ax
		ret
CompterFleurs   ENDP

;-------------------------------------------------------------------
; CompterObjsFow:
; Cette fonction compte le nombre d'obj d'avant-plan n'ont pas
; été ramassés.
; Paramètre de sortie
; AX= Nbr d'objs
;-------------------------------------------------------------------

CompterObjsFow  PROC
		push es
		push si
		xor ax,ax

		set es,LIBRAIRY
		mov si,ChgingDefs

Nx:             ifedo word ptr es:[si],-1, Bye

		actifin byte ptr es:[si+ScrStat], Diamant, Fruit, <inc ax>

		.if (byte ptr es:[si+ScrStat]>=Diamant) && (byte ptr es:[si+ScrStat]<=DeadlyItem)
			inc ax
		.else
		     .if (byte ptr es:[si+ScrStat]==Oxygen)
			 inc ax
		     .endif
		.endif
		add si,8
		jmp Nx

Bye:
		pop es
		pop si
		ret
CompterObjsFow  ENDP

;------------------------------------------------------------------

EndSection      PROC

		AfficherTitre EndSectionY, DATA, offset EndSectionTxt


		.if PlyLifeForce > QteLifeForceNormal
		     AfficherTitre YSectionBonus, DATA, offset SectionBonusTxt

		     .while PlyLifeForce > QteLifeForceNormal
			sub PlyLifeForce, 1
			AddToScore 100
			call AfficherGameInfo
			pause 10
		     .endw

		     mov PlyLifeForce, QteLifeForceNormal

		.else
		    AfficherTitre YSectionBonus, DATA, offset NoSectionBonusTxt
		.endif
		ret

EndSection      ENDP

;-----------------------------------------------------------------------
; Cette portion du programme se charge d'obtenir le nouveau tableau,
; de trier le OBJ statiques qu'il contient, d'en faire une map statique
; et ajuster l'écran.
;-----------------------------------------------------------------------
GameSys         PROC
		set DS,DATA
		call LucasUndraw

		.if byte ptr RecInProgress== VRAI
			HCreat offset NameRecFile, RecFile
		.endif

; Modifier la taille de l'écran pour accomoder l'écran, et charger le
; Ptr de la définition du tableau.
		mov byte ptr ScrHei,21
		mov word ptr NomPtr, offset _DAT

; Mettre à Zéro tous les compteurs, accumulateurs et drapeau qui doivent
; indique soit la quantité d'oxygène, la force vie, le nbr de vie,
; l'indicateur de chute ou de morcure.

		mov byte ptr AniFlag, 0
		mov byte ptr PlyBite, Faux
		mov word ptr PlyOxygen, QteOxygenNormal
		mov word ptr PlyLifeForce, QteLifeForceNormal
		mov byte ptr PlyNbVies, QteLivesNormal
		mov byte ptr PlyJumpFlag, Faux
		mov byte ptr PlyFallFlag, Faux
		mov word ptr CTimer, 0
		EraseMem DATA,offset PlyScore,8
		mov word ptr MapLevelExtension, offset _MapLevelExtensionProc

; Charge un nouveau tableau en mémoire.
EntryToNxLevel:

		HSetHandler TmpEHandler
		HCreat offset VLAMITS2_TMP, TmpFile
		HWrite DATA, StartTmp, GameTamponSize, TmpFile
		HClose TmpFile
		HSetHandler EHandler

		set ds, DATA
		mov si,word ptr NomPtr

		cmp byte ptr [si], "*"
		je YouWin

		.if byte ptr [si]=="@"
			add word ptr NomPtr, 3

			mov al, byte ptr [si+1]
			sub al,30h
			mov ah,10
			mul ah

			add al,byte ptr [si+2]
			sub al,30h

			mov byte ptr GameDoodle, al

		.else
			mov byte ptr GameDoodle,0

		.endif


		.if (GameDoodle==SectionCompleted) && (RestoreGame==FAUX)
			call EndSection
		.endif

		.if RestoreGame== VRAI
			skipchar DATA, NomPtr, 0
			inc NomPtr
			mov dx, NomPtr
			call LoadIms
			skipchar DATA, NomPtr, 0
			inc NomPtr
			skipchar DATA, NomPtr, 0
			inc NomPtr
			mov RestoreGame, FAUX

		.else
			.if byte ptr DemoOn==FAUX
				call LoadLevel
				call TrierObjs
			.else
				call LoadDemo
				mov word ptr PlyLifeForce, QteLifeForceNormal
				call TrierObjs
			.endif
		.endif

; Il est par la suite nécessaire d'identifier quellle image statique
; correspond à la première FRAME de Annie. (BaseActFrame)

		set ds,DATA
		call ChangeScrSize
		call MapLevel
		call MakeImaPtrTable
		FindLeadingChar "*"
		mov word ptr BaseActFrame, ax

		; On doit changer les STOP en BLANK.
		FindLeadingChar "!"
		mov word ptr StopFrame, ax
		FindLeadingChar "#"
		mov word ptr BloquerFrame, ax
		FindLeadingChar "_"
		mov word ptr BlankFrame, ax
		call ChangeStopsIntoBlanks
		call ChangeBloquerIntoBlanks

		FindLeadingChar "+"
		mov word ptr _PtsFrame, ax

		FindLeadingChar YoungCannibalCar
		mov word ptr CannibalBaseFrame, ax

		FindLeadingChar InMangaCar
		mov word ptr InMangaBaseFrame, ax

		mov byte ptr ScrLen,MaxColonnes
		call CompterFleurs
		ifndo byte ptr NbrFleurs,0,AFleurs
		mov dx,offset XFleurTxt
		jmp SendErrorMessage
AFleurs:

; L'écran est déssiné pour m'assuser que le programme fonctionne, toujours.
; Car avec ce maudit programme, on ne sait jamais.
		call InitJoueur
		call DessinerEcran

		call PickUp
		call StallGameInfo
		call AfficherGameInfo

; Boucle central qui permet la gestion du jeu via la coordination des
; différents sous-modules qui le compose.

Main:
		set es, LIBRAIRY

		ifedo word ptr NbrFleurs,0, FinDeTableau
		call RepositionnerPLY
		inc word ptr CTimer
		cmp word ptr CTimer, GameSpeed
		jb NotCreaTime
		mov word ptr CTimer,0
		.if byte ptr PlyJumpFlag!=0
			call DoJump
		.endif

		call FallModulator

		call CreaturesModule
		.if PlyLifeForce==0
			call DrawFow
			mov PlyOxygen,0
			.if RecInProgress == VRAI
				HClose RecFile
				mov byte ptr RecInProgress,FAUX
				jmp GameOverSys
			.endif

			.if DemoOn == VRAI
				HClose RecFile
				jmp EntryToNxLevel

			.else
				jmp GameOverSys
			.endif
		.endif

		call DrawFow

		.if word ptr PlyBite != 0
			call AfficherGameInfo
			mov byte ptr BiteDelai, 5
			mov al,byte ptr PlyBite
			xor ah,ah
			mov byte ptr PlyBite,Faux
			DecLifeForce ax
	                .if SB_ACTIVE == VRAI  && (StatusWord ==0)
				pushall
				set es, FONT4
				mov di, 1ah + SND_Ouch
				mov bx, Const_ReadSample
				call CTVoiceDRV
				popall
			.endif
		.endif

NoBite:

		.if byte ptr BiteDelai == 1
			mov byte ptr BiteDelai,0
			call AfficherGameInfo

		.else
			ifedo byte ptr BiteDelai,0, NoBiteDelai
			dec byte ptr BiteDelai

		.endif

NoBiteDelai:
		call PickUp
		call PlyOxyCtrl

NotCreaTime:

		mov al,byte ptr CTimer
		and al,15
		cmp al,1
		jne NoPickUp

		.if byte ptr PlyJumpFlag ==0
			 IsFalling word ptr PlyPtr
			.if al==Vrai
				 CanWalk word ptr PlyPtr, EnBas
				.if al==Vrai
					mov byte ptr PlyFallFlag, Vrai
					jmp Fall
				.else
					mov byte ptr PlyFallFlag, Faux
				.endif

			.else
				mov byte ptr PlyFallFlag, Faux
			.endif

		.else
			mov byte ptr PlyFallFlag,Faux
		.endif

NoPickUp:

		; -----------------------------------------------------
		; Il est nécessaire de vérifier si le joueur est MORT.
		ifndo byte ptr PlyJumpFlag, 0,Main

		.if PlyLifeForce == 0

			mov PlyOxygen,0
			.if RecInProgress == VRAI
				HClose RecFile
				mov byte ptr RecInProgress,FAUX
				jmp GameOverSys
			.endif

			.if DemoOn == VRAI
				HClose RecFile
				jmp EntryToNxLevel

			.else
				jmp GameOverSys
			.endif
		.endif


		 IsPlayerInLava
		.if (al==Vrai) && (byte ptr PlyFallFlag==Faux)

			mov PlyOxygen,0
			.if RecInProgress == VRAI
				HClose RecFile
				mov byte ptr RecInProgress,FAUX
				jmp GameOverSys
			.endif

			.if DemoOn == VRAI
				HClose RecFile
				jmp EntryToNxLevel

			.else
				jmp GameOverSys
			.endif

		.endif


		; -----------------------------------------------------
		; Il est maintenant temps d'effectuer la lecture
		; du clavier.
		call Getax

	       .if (ax!=0) && (DemoOn==VRAI)
			HClose RecFile
			mov NoShow, VRAI
			mov byte ptr RecInProgress,FAUX
			ret
	       .endif

	       .if (byte ptr RecInProgress ==VRAI)
			.if ax==0
				.if ZeroCounter!=65535
					inc ZeroCounter
				.else
					mov byte ptr RecBuffer, al
					HWrite DATA, offset RecBuffer, 1 , RecFile
					HWrite DATA, offset ZeroCounter, 2 , RecFile
					mov ZeroCounter,0
				.endif
			.else
					.if ZeroCounter !=0
						mov byte ptr RecBuffer, 0
						HWrite DATA, offset RecBuffer, 1 , RecFile
						HWrite DATA, offset ZeroCounter, 2 , RecFile
						mov ZeroCounter,0
					.endif
					mov byte ptr RecBuffer, al
					HWrite DATA, offset RecBuffer, 1 , RecFile
			.endif
		.endif

		.if (byte ptr DemoOn==VRAI)
			.if ZeroCounter==0
				HReadFile DATA, offset RecBuffer, 1, RecFile
				.if byte ptr RecBuffer ==0
					HReadFile DATA, offset ZeroCounter, 2, RecFile

				.else
					mov al, byte ptr RecBuffer

				.endif
			.else
				dec ZeroCounter
				mov al,0
			.endif
		.endif

		ifsedo al," ", PauseGame
		ifedo al,"8",Haut
		ifedo al,"2",Bas
		ifedo al,"4",Gauche
		ifedo al,"6",Droite
		ifedo ah,72,Haut
		ifedo ah,80,Bas
		ifedo ah,75,Gauche
		ifedo ah,77,Droite
		ifedo al,"7",JumpLeft
		ifedo al,"9",JumpRight
		ifedo ah,HomeKey, JumpLeft
		ifedo ah,PgUpKey, JumpRight

		ifedo al,"/",Tricher
		ifedo ah, F1KEY, GameOptions

		.if (al== RecOnKey) && (DemoOn==VRAI)
			HClose RecFile
			jmp EntryToNxLevel
		.endif

		.if (al== RecOnKey) && (RecInProgress==VRAI)
			HClose RecFile
			mov byte ptr RecInProgress,FAUX
			ret
		.endif


Drawer:         jmp Main

		;-----------------------------------------------------
		; Gère les sauts effectués
DoJump:
		mov al,byte ptr PlyJumpFlag
		dec byte ptr PlyJumpFlag

		ifedo byte ptr PlyDir, AGauche, _JumpLeft
		;-------------------------------------------------

_JumpRight:     ifndo al,1, JR2
		set es,LIBRAIRY
		CanWalk word ptr PlyPtr, EnBas
		ifzdo al,MajEnBas

		 IsMid
			RemoveActor word ptr PlyPtr
			mov si, word ptr PlyPtr
			inc byte ptr es:[si+ScrY]
			call AdjPlyFrame
			DrawEntry word ptr PlyPtr

		call Pickup
		IsFalling word ptr PlyPtr
		mov byte ptr PlyFallFlag, al
		ret
JR2:
		set es,LIBRAIRY
		CanWalk word ptr PlyPtr, ADroite
		ifzdo al,MajEnBas

		mov si, word ptr PlyPtr

		.if byte ptr es:[si+ScrX]!=0

			 IsMid
			.if al== VRAI && (byte ptr MX!=0)

				call ScrollRg
				copyscr SCREEN2,SCREEN

				inc byte ptr MX
				inc byte ptr es:[si+ScrX]
				mov byte ptr PlyDir, ADroite
				call AdjPlyFrame

				pushall
				set gs,SCREEN
				set es,LIBRAIRY
				mov si,Chgingdefs
				call DrawScript
				popall

				copyscr 0a000h, SCREEN
				copyscr SCREEN, SCREEN2

			.else

				RemoveActor word ptr PlyPtr
				mov si,word ptr PlyPtr
				mov byte ptr PlyDir, ADroite
				inc byte ptr PlyAFlag
				and byte ptr PlyAFlag,3
				inc byte ptr es:[si+ScrX]
				call AdjPlyFrame
				DrawEntry word ptr PlyPtr
				call Pickup

			.endif

		.endif

			call Pickup

		ret

		;----------------------------------------------------
_JumpLeft:      ifndo al,1, JL2
JL1:
		set es,LIBRAIRY
		CanWalk word ptr PlyPtr, EnBas
		ifzdo al,MajEnBas

		 IsMid
		;.if al==VRAI && (byte ptr MX!=0)


			RemoveActor word ptr PlyPtr
			mov si, word ptr PlyPtr
			inc byte ptr es:[si+ScrY]
			call AdjPlyFrame
			DrawEntry word ptr PlyPtr
		;.endif

		call Pickup
		IsFalling word ptr PlyPtr
		mov byte ptr PlyFallFlag, al
		ret
JL2:
		set es,LIBRAIRY
		CanWalk word ptr PlyPtr, AGauche
		ifzdo al,MajEnBas

		mov si, word ptr PlyPtr

		.if byte ptr es:[si+ScrX]!=0

			 IsMid
			.if (byte ptr MX!=0)

				call ScrollLf
				copyscr SCREEN2,SCREEN

				dec byte ptr MX
				dec byte ptr es:[si+ScrX]
				mov byte ptr PlyDir, AGauche
				call AdjPlyFrame

				pushall
				set gs,SCREEN
				set es,LIBRAIRY
				mov si,Chgingdefs
				call DrawScript
				popall

				copyscr 0a000h, SCREEN
				copyscr SCREEN, SCREEN2

			.else

				RemoveActor word ptr PlyPtr
				mov si,word ptr PlyPtr
				mov byte ptr PlyDir, AGauche
				inc byte ptr PlyAFlag
				and byte ptr PlyAFlag,3
				dec byte ptr es:[si+ScrX]
				call AdjPlyFrame
				DrawEntry word ptr PlyPtr
				call Pickup

			.endif

		.endif

		call Pickup

		ret

		;--------------------------------------------------------
		; Majoré par en bas après un saut À GAUCHE/À DROITE,
		; qui a échoué et par conséquent éviter que le personnage
		; ne sorte de l'écran.
		;--------------------------------------------------------

MajEnBas:
		 CanWalk word ptr PlyPtr, EnBas
		.if (al==VRAI)

			set es, LIBRAIRY
			RemoveActor word ptr PlyPtr
			mov si, word ptr PlyPtr
			inc byte ptr es:[si+ScrY]
			DrawEntry word ptr PlyPtr

		.endif
		mov byte ptr PlyJumpFlag, FAUX
		ret

		;--------------------------------------------------------
		; Cette portion du programme fera le joueur tomber.
Fall:           CanWalk word ptr PlyPtr, EnBas
		;ShowAL
		ifzdo al,Drawer

		set es, LIBRAIRY

		mov si,word ptr PlyPtr
		;mov byte ptr PlyDir, EnHaut
		;inc byte ptr PlyAFlag
		;and byte ptr PlyAFlag,3
		inc byte ptr es:[si+ScrY]
		;call AdjPlyFrame
		;CopySeg 0a000h,SCREEN

		mov si,word ptr PlyPtr
		mov al,es:[si+ScrY]
		sub al,byte ptr MY

		.if al>9
		; INCMY
			call ScrollDn
			inc byte ptr MY
		.endif

		.if (al<9) && (byte ptr MY !=0)
		; DECMY

			call ScrollUp
			dec byte ptr MY
		.endif

		.if al==9
			isMid
		.endif

		call DessinerBck
		call DrawFow
		call PickUp
		jmp Main

		;-------------------------------------------------------
		; Permet un saut à gauche
JumpLeft:       set es,LIBRAIRY

		ifndo byte ptr PlyFallFlag, 0, Main

		CanWalk word ptr PlyPtr, SautAGauche
		ifzdo al,Main

		mov si, word ptr PlyPtr
		.if byte ptr es:[si+ScrY]!=0
			mov byte ptr PLYJumpFlag,3
		.else
			mov byte ptr PLYJumpFlag,FAUX
			jmp Main
		.endif

                .if SB_ACTIVE == VRAI  && (StatusWord ==0)
			pushall
			set es, FONT4
			mov di, 1ah + SND_Jump
			mov bx, Const_ReadSample
			call CTVoiceDRV
			popall
		.endif

		.if byte ptr es:[si+ScrX]!=0

			 IsMid
			.if al== VRAI && (byte ptr MX!=0)

				.if byte ptr es:[si+ScrY]!=0
					dec byte ptr es:[si+ScrY]
				.endif

				call ScrollLf
				copyscr SCREEN2,SCREEN

				dec byte ptr MX
				dec byte ptr es:[si+ScrX]
				mov byte ptr PlyDir, AGauche
				call AdjPlyFrame

				pushall
				set gs,SCREEN
				set es,LIBRAIRY
				mov si,Chgingdefs
				call DrawScript
				popall

				copyscr 0a000h, SCREEN
				copyscr SCREEN, SCREEN2

			.else

				RemoveActor word ptr PlyPtr
				mov si,word ptr PlyPtr
				.if byte ptr es:[si+ScrY]!=0
					dec byte ptr es:[si+ScrY]
				.endif

				mov byte ptr PlyDir, AGauche
				inc byte ptr PlyAFlag
				and byte ptr PlyAFlag,3
				dec byte ptr es:[si+ScrX]
				call AdjPlyFrame
				DrawEntry word ptr PlyPtr
				call Pickup

			.endif

		.endif
		call Pickup
		jmp Main

		;--------------------------------------------------------
		; Permet un saut à droite
JumpRight:

		set es,LIBRAIRY
		ifndo byte ptr PlyFallFlag, 0, Main

		CanWalk word ptr PlyPtr, SautADroite
		ifzdo al,Main

		mov si, word ptr PlyPtr

		.if byte ptr es:[si+ScrY]!=0
			mov byte ptr PLYJumpFlag,3
		.else
			mov byte ptr PLYJumpFlag,0
			jmp Main
		.endif

                .if SB_ACTIVE == VRAI  && (StatusWord ==0)
			pushall
			set es, FONT4
			mov di, 1ah + SND_Jump
			mov bx, Const_ReadSample
			call CTVoiceDRV
			popall
		.endif

		IsMid
		.if al==VRAI

			.if byte ptr es:[si+ScrY]!=0
				dec byte ptr es:[si+ScrY]
			.endif
			call Scrollrg
			copyscr SCREEN2,SCREEN

			inc byte ptr MX
			inc byte ptr es:[si+ScrX]
			mov byte ptr PlyDir, ADroite
			call AdjPlyFrame

			pushall
			set gs,SCREEN
			set es,LIBRAIRY
			mov si,Chgingdefs
			call DrawScript
			popall

			copyscr 0a000h, SCREEN
			copyscr SCREEN, SCREEN2

		.else

			RemoveActor word ptr PlyPtr
			.if byte ptr es:[si+ScrY]!=0
				dec byte ptr es:[si+ScrY]
			.endif
			mov si,word ptr PlyPtr
			mov byte ptr PlyDir, ADroite
			inc byte ptr PlyAFlag
			and byte ptr PlyAFlag,3
			inc byte ptr es:[si+ScrX]
			call AdjPlyFrame
			DrawEntry word ptr PlyPtr
			call Pickup

		.endif

		jmp Main


	;-------------------------------------------------------------
	; Déplacements habituels:
	; EnHaut, EnBas, à gauche et à droite.
	;-------------------------------------------------------------
		; Gère le déplacement du joueur, lorsque celui-ci veut
		; aller par en haut.
Haut:           ;ifndo byte ptr PlyFallFlag,0,Main
		CanWalk word ptr PlyPtr, EnHaut
		;ShowAL
		ifzdo al,Drawer
		dec byte ptr es:[si+ScrY]

		IsFalling word ptr PlyPtr
		ifzdo al, NotFalling

		inc byte ptr es:[si+ScrY]
		jmp Main

NotFalling:
		mov byte ptr PlyDir, EnHaut
		inc byte ptr PlyAFlag
		and byte ptr PlyAFlag,3

		;ifedo byte ptr MY,0,NoScrollUP

                ;********** PLAY A DING ? **************
                pushall
		.if SB_ACTIVE==VRAI && StatusWord==0
		        mov bx, es:[si+ScrX]
                    	mov al, [bx]
                    	mov ah, [bx+1]
                    	mov dl, [bx+256]
                    	mov dh, [bx+257]
		     .if (al==ladderDING)||(ah==ladderDING)||(dl==LadderDing)||(dh==LadderDing)
				set es, FONT4
				mov di, 1ah + SND_Metal
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                     .else
		          .if (al==BRIDGE)||(ah==BRIDGE)||(dl==BRIDGE)||(dh==BRIDGE)
				set es, FONT4
				mov di, 1ah + SND_Walk
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                          .endif

       		     .endif
                .endif
                popall

		;*********************************************************************

		.if byte ptr MY!=0
			call ScrollUp
			dec byte ptr MY
		.endif
NoScrollUP:     mov si,word ptr PlyPtr

		call AdjPlyFrame
		;CopySeg 0a000h,SCREEN
		call DessinerBck
		call DrawFow
		call PickUp
		jmp Main

		;-----------------------------------------------------
		; Gère le déplacement du joueur, lorsque celui-ci veut
		; aller par en bas.
Bas:            CanWalk word ptr PlyPtr, EnBas
		ifzdo al,Drawer
		;ShowAL

		set es,LIBRAIRY
		mov si,word ptr PlyPtr
		mov al,es:[si+ScrY]
		inc al
		;cmp al,9
		;ja INC_MY
		;jb DEC_MY
		;jmp Bye
		sub al,byte ptr MY


		.if al>9
			call ScrollDn
			inc byte ptr MY
		.endif
                ;********** PLAY A DING ? **************
                pushall
		.if SB_ACTIVE==VRAI && StatusWord==0
		        mov bx, es:[si+ScrX]
                    	mov al, [bx]
                    	mov ah, [bx+1]
                    	mov dl, [bx+256]
                    	mov dh, [bx+257]
		     .if al==ladderDING||ah==ladderDING||dl==LadderDing||dh==LadderDing
				set es, FONT4
				mov di, 1ah + SND_Metal
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                     .else
		          .if al==BRIDGE||ah==BRIDGE||dl==BRIDGE||dh==BRIDGE
				set es, FONT4
				mov di, 1ah + SND_Walk
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                          .endif

       		     .endif
                .endif
                popall

		;*********************************************************************

		mov si,word ptr PlyPtr
		mov byte ptr PlyDir, EnHaut
		inc byte ptr PlyAFlag
		and byte ptr PlyAFlag,3
		inc byte ptr es:[si+ScrY]
		call AdjPlyFrame
		;CopySeg 0a000h,SCREEN
		call DessinerBck
		call DrawFow
		call PickUp
		jmp Main

		;-----------------------------------------------------
		; Gère le déplacement du joueur, lorsque celui-ci veut
		; aller à gauche.
Gauche:         CanWalk word ptr PlyPtr, AGauche
		ifzdo al,Drawer

		.if byte ptr es:[si+ScrX] !=0
			 IsMid
			.if (byte ptr MX !=0)
				call ScrollLf
				CopyScr SCREEN2, SCREEN
				mov si,word ptr PlyPtr
				mov byte ptr PlyDir, AGauche
				inc byte ptr PlyAFlag
				and byte ptr PlyAFlag,3
				dec byte ptr es:[si+ScrX]
				call AdjPlyFrame
				dec byte ptr MX

				pushall
				set gs,SCREEN
				set es,LIBRAIRY
				mov si,Chgingdefs
				call DrawScript
				popall

				CopyScr 0a000h,SCREEN
				CopyScr SCREEN,SCREEN2


			.else
				RemoveActor word ptr PlyPtr
				mov si,word ptr PlyPtr
				mov byte ptr PlyDir, AGauche
				inc byte ptr PlyAFlag
				and byte ptr PlyAFlag,3
				dec byte ptr es:[si+ScrX]
				call AdjPlyFrame
				DrawEntry word ptr PlyPtr
			.endif
		.endif

                ;********** PLAY A DING ? **************
                pushall
		.if SB_ACTIVE==VRAI && StatusWord==0
		        mov bx, es:[si+ScrX]
                    	mov al, [bx]
                    	mov ah, [bx+1]
                    	mov dl, [bx+256]
                    	mov dh, [bx+257]
		     .if al==ladderDING||ah==ladderDING||dl==LadderDing||dh==LadderDing
				set es, FONT4
				mov di, 1ah + SND_Metal
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                     .else
		          .if al==BRIDGE||ah==BRIDGE||dl==BRIDGE||dh==BRIDGE
				set es, FONT4
				mov di, 1ah + SND_Walk
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                          .endif

       		     .endif
                .endif
                popall

		;*********************************************************************
		call Pickup

		jmp Main

		;-----------------------------------------------------
		; Gère le déplacement du joueur, lorsque celui-ci veut
		; aller à droite.
Droite:         CanWalk word ptr PlyPtr, ADroite
		ifzdo al,Drawer

		 IsMid
		.if al==Vrai
			call ScrollRg
			CopyScr SCREEN2, SCREEN
			mov si,word ptr PlyPtr
			mov byte ptr PlyDir, ADroite
			inc byte ptr PlyAFlag
			and byte ptr PlyAFlag,3
			inc byte ptr es:[si+ScrX]
			call AdjPlyFrame
			inc byte ptr MX

			pushall
			set gs,SCREEN
			set es,LIBRAIRY
			mov si,Chgingdefs
			call DrawScript
			popall

			CopyScr 0a000h,SCREEN
			CopyScr SCREEN,SCREEN2

		.else
			RemoveActor word ptr PlyPtr
			mov si,word ptr PlyPtr
			mov byte ptr PlyDir, ADroite
			inc byte ptr PlyAFlag
			and byte ptr PlyAFlag,3
			inc byte ptr es:[si+ScrX]
			call AdjPlyFrame
			DrawEntry word ptr PlyPtr
		.endif

                ;********** PLAY A DING ? **************
                pushall
		.if SB_ACTIVE==VRAI && StatusWord==0
		        mov bx, es:[si+ScrX]
                    	mov al, [bx]
                    	mov ah, [bx+1]
                    	mov dl, [bx+256]
                    	mov dh, [bx+257]
		     .if al==ladderDING||ah==ladderDING||dl==LadderDing||dh==LadderDing
				set es, FONT4
				mov di, 1ah + SND_Metal
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                     .else
		          .if al==BRIDGE||ah==BRIDGE||dl==BRIDGE||dh==BRIDGE
				set es, FONT4
				mov di, 1ah + SND_Walk
				mov bx, Const_ReadSample
			        call CTVoiceDRV
                          .endif

       		     .endif
                .endif
                popall

		;*********************************************************************

		call Pickup
		jmp Main
_Out:           ret


FinDeTableau:
		call DrawFow
		call AfficherGameInfo
		call LucasUndraw

		erasemem 0a000h, YBonus5000TR * 0a00h, 0a00h
		mov cx,word ptr PlYLifeForce
		add cx,1000
		shr cx,6
BonusLife:      AddToScore 64
		pause 10
		call AfficherGameInfo
		loop BonusLife

		call CompterObjsFow
		.if ax==0
	                LoadVOC offset _5000PTS_VOC, FONT3, 0
                        .if SB_ACTIVE== VRAI
			   pushall
	 		   set es, FONT3
			   mov di, 1ah + 0
			   mov bx, Const_ReadSample
			   call CTVoiceDRV
			   popall
                        .endif

					AfficherTitre YBonus5000TR, DATA, offset Bonus5000TR
					mov cx,5000/50
		    AddBonus5000:
					AddToScore 50
					pause 10
					call AfficherGameInfo
					loop AddBonus5000

		.endif

		jmp EntryToNxLevel

Tricher:        call DrawFow
		call AfficherGameInfo
		call LucasUndraw

		AfficherTitre YBonus5000TR, DATA, offset TricherTxt
		jmp EntryToNxLevel

YouWin:
		ret


GameOverSys:
		call AfficherGameInfo
		DrawMsg 0,(MaxLignes/2)

GOS:            call getax
		ifedo al,"r", Recommencer
		ifedo al,"R", Recommencer
		ifedo al,"c", Commencer
		ifedo al,"C", Commencer
		jmp GOS

Recommencer:    call LucasUndraw

		HopenForRead offset VLAMITS2_TMP, TmpFile
		HReadFile DATA, StartTmp, GameTamponSize, TmpFile
		HClose TmpFile
		jmp EntryToNxLevel

Commencer:      ret


TmpEHandler:
		mov dx,offset TmpErrorTxt
		jmp SendErrorMessage

GameOptions:    DrawMsg 1, 8
GO:
		call getax
		.while (al!=" ") && (ah!=F1KEY)
			ifedo al,"v", VHi
			ifedo al,"V", VHi
			ifedo al,"r", Recommencer
			ifedo al,"R", Recommencer
			ifedo al,"c", Commencer
			ifedo al,"C", Commencer
			ifedo al,"-", _RestoreGame
			ifedo al,"_", _RestoreGame
			ifedo al,"=", SaveGame
			ifedo al,"+", SaveGame


			call getax
		.endw

		call DessinerEcran
		call AfficherGameInfo
		call StallGameInfo
		;call MapLevel
		jmp Main

VHi:            call LucasUndraw
		erasemem 0a000h, 22*0a00h, 3*0a00h
		call DrawBoard
		AfficherTitre 23,DATA, offset SpaceToCont
		call getax
		.while al!=" "
			call getax
		.endw

		call DessinerEcran
		call StallGameInfo
		call AfficherGameInfo
		;call MapLevel
		jmp Main

SaveGame:
		DrawMsg 4, 5
		call getax
		.while (al!=" ") && (ah!=F1KEY)


		     .if (al>="1") && (al<="9")
			  jmp MkSave
		     .endif

		     call getax
		.endw

		call DessinerEcran
		call StallGameInfo
		call AfficherGameInfo
		;call MapLevel
		jmp Main

MkSave:
		set ds,DATA
		mov byte ptr Savegame_XXX_ -1,al

		HCreat offset SaveGame_XXX, SFile
		HWrite DATA, StartTmp, GameTamponSize, SFile

		; [OFFSET SCRDEFS]
		set es,LIBRAIRY
		mov si,offset ScrDefs
		.while word ptr es:[si] != -1
		     add si,8
		.endw
		add si,8
		sub si, offset ScrDefs
		mov word ptr DataSize, si
		HWrite DATA, offset DataSize,2, SFile
		HWrite LIBRAIRY, offset ScrDefs, word ptr DataSize, SFile

		; [CHANGINGDEFS]
		set es,LIBRAIRY
		mov si,ChgingDefs
		.while word ptr es:[si] != -1
		     add si,8
		.endw
		add si,8
		sub si, offset ChgingDefs
		mov word ptr DataSize, si
		HWrite DATA, offset DataSize,2, SFile
		HWrite LIBRAIRY, ChgingDefs, word ptr DataSize, SFile

		; [C'EST FINI... HA HA HA!]
		Hwrite DATA, offset _DAT, Size_DAT, SFile
		HWrite DATA, offset COPYRIGHT, offset COPYRIGHT_ - offset COPYRIGHT, SFile
		HClose SFILE

		call DessinerEcran
		call StallGameInfo
		call AfficherGameInfo
		;call MapLevel
		jmp Main


_RestoreGame:
		DrawMsg 5, 5
		call getax
		.while (al!=" ") && (ah!=F1KEY)


		     .if (al>="1") && (al<="9")
			  jmp MkLoad
		     .endif

		     call getax
		.endw

		call DessinerEcran
		call StallGameInfo
		call AfficherGameInfo
		;call MapLevel
		jmp Main

MkLoad:
		set ds,DATA
		mov byte ptr Savegame_XXX_ -1,al

		HSetHandler RestoreError
		HOpenForRead offset SaveGame_XXX, SFile
		HReadFile DATA, StartTmp, GameTamponSize, SFile

                EraseSeg LIBRAIRY

		; [OFFSET SCRDEFS]
		HReadFile DATA, offset DataSize,2, SFile
		HReadFile LIBRAIRY, offset ScrDefs, word ptr DataSize, SFile

		; [CHANGINGDEFS]
		HReadFile DATA, offset DataSize,2, SFile
		HReadFile LIBRAIRY, ChgingDefs, word ptr DataSize, SFile

		; [C'EST FINI... HA HA HA!]
		HReadFile DATA, offset _DAT, Size_DAT, SFile
		movw NomPtr, OldNomPtr

		HClose SFILE

		;call DessinerEcran
		;call StallGameInfo
		;call AfficherGameInfo

		mov RestoreGame, VRAI
		jmp EntryToNxLevel

RestoreError:
		HSetHandler EHandler
		Locate 0,0
		print offset RestoreErrortxt
		Pause 30000
		call DessinerEcran
		call StallGameInfo
		call AfficherGameInfo
		jmp Main

		;call MapLevel
		;jmp Main

GameSys         ENDP
VLAMITS2    ENDP                           ; Fin de la procedure

align 4
Int21OldHandler dd 0

; *********************************************************************
; The Interrupt 21h's HANDLER SYSTEM
; *********************************************************************
Int21Handler:
		.if ah==4ch

                     .if SB_ACTIVE==VRAI
	                 pushall
	                 mov bx, 9		  ; Cut-off all contact with
                         call CtVoiceDRV	  ; CT-VOICE before returning
                         popall			  ; to MS-DOS.
                     .endif

                     mov dx, word ptr Int21OldHandler
                     set ds, word ptr Int21OldHandler+2
                     push ax
                     mov ah,25h         ; sub fonction
                     mov al,21h         ; int no
                     int 21h
                     pop ax
                .endif

                jmp dword ptr Int21OldHandler

; *********************************************************************

InitSystem      PROC

		mov ah,35h		; GET INT 21h' s VECTOR
                mov al,21h
                int 21h

                mov word ptr Int21OldHandler, bx
                mov word ptr Int21OldHandler+2, es

                mov ah,25h
                mov al,21h
                set ds,CODE
                mov dx, offset Int21Handler
                int 21h

                set ds,DATA
                .if HasSound==Faux
			HSetHandler offset SbInfoHandler
			HOpenForRead offset CtVoice_DRV, CtvFile
			HReadFile CtVoice, 0, CtVoiceSize, CtvFile
			HClose CtvFile
			HSetHandler offset EHandler
                .else
                .endif

		mov bx, const_InitCtVoice
		call CtVoiceDRV

		.if ax== 0
			print offset SbFoundTxt
        	        print offset sbgenericInfo
			pause 35000

			 set es,DATA
			 mov di, offset StatusWord
			 mov bx, const_AddressStatWORD
			 call CtVoiceDRV

			 ; Active les haut parleurs
			 mov bx, const_ActivateSpeaker
			 mov al, VRAI
			 call CtVoiceDRV

			 set ds,DATA
			 mov word ptr SB_ACTIVE, VRAI

			call Vlamits2
		.else
		     .if ax==1
			 print offset SbNotFoundTxt
                         print offset sbgenericInfo
			 pause 35000
			 call Vlamits2

		     .else
			  .if ax==2
			      print offset SbAddXTxt
       	                      print offset sbgenericInfo
			      pause 35000
			      call Vlamits2

			  .else
			       .if ax==3
				    print offset SbIntXTxt
	                            print offset sbgenericInfo
				    pause 35000
				    call Vlamits2

			       .else
				    print offset SbErrInc
        	                    print offset sbgenericInfo
				    pause 35000
				    call Vlamits2

			       .endif

			   .endif

		     .endif

		.endif

SbInfoHandler:  print offset SbDriverInfo
		pause 35000
		call Vlamits2
InitSystem      ENDP

;---------------------------------------------------------------
CODE ENDS                                ; Fin du programme
END     InitSystem                           ; Point d'entree
;---------------------------------------------------------------
