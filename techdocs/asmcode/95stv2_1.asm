; ****************************************************************
;
; 	ASSEMBLY MODULES RUNTIME LIBRAIRY: 95STV2_1.ASM
;
; 		COPYRIGHT 1995 FRANCOIS BLANCHETTE
;
; ****************************************************************

ASSUME SS:STACK, DS:DATA, ES:LIBRAIRY

TITLE RUNTIME_LIBRAIRY_95STV2_1

INCLUDE \MASM61\LISTING\SSFSM95.INC
INCLUDE \MASM61\LISTING\IOSYSTEM.INC

USEREPV2	; 94REPV2.ASM
USESTATV2	; 94STATV2.ASM
USESTATV2_1	; 95STV2_1.ASM

STACK     SEGMENT STACK
STACK     ENDS

DATA SEGMENT 'DATA' PUBLIC
COPYRIGHT	    DB "95STV2_1 RUNTIME LIBRAIRY "
		    DB "(C) 1995 FRANCOIS BLANCHETTE."

ALIGN 2
IMAPTRTABLE	    DW 2048 DUP (0)

ALIGN 2
PLY2OFFSET	    DW 0
DRAWOFFSET	    DW 0
IMANAMEVAR	    DW 0
MAPLEVELEXTENSION   DW MAPLEVELEXTENSIONPROC
DATA ENDS

LIBRAIRY SEGMENT PUBLIC 'LIBRAIRY'
;IMSDEFS		DB 32768 DUP (0)
;SCRDEFS		DB 16384 DUP (0)
;SCRTEMP		DB 04096 DUP (0)
;IMSNAMES        	DB 08192 DUP (0)
;STODEFS		DB 04096 DUP (0)
LIBRAIRY ENDS

FONT SEGMENT PUBLIC 'FONT'
FONT ENDS

FONT2 SEGMENT PUBLIC 'FONT2'
FONT2 ENDS

FONT3 SEGMENT PUBLIC 'FONT3'
FONT3 ENDS

FONT4 SEGMENT PUBLIC 'FONT4'
FONT4 ENDS

SCREEN SEGMENT 'SCREEN' PUBLIC
SCREEN ENDS

IMSNAMEPTR  EQU WORD PTR IMANAMEVAR

;------------------------------------------------------------------------
CODE SEGMENT 'CODE' PUBLIC
;------------------------------------------------------------------------
.386

MAPLEVELEXTENSIONPROC PROC
		RET
MAPLEVELEXTENSIONPROC  ENDP


MAKEIMAPTRTABLE PROC
    		PUSHALL

                SET DS,DATA
                SET ES,LIBRAIRY

                MOV DI,OFFSET IMAPTRTABLE
		XOR SI,SI
                MOV IMSNAMEPTR, OFFSET IMSNAMES

NXIMA:          MOV BX,IMSNAMEPTR
                CMP BYTE PTR ES:[BX],0
                JE BYE
                SKIPCHAR LIBRAIRY,IMSNAMEPTR, 13

		MOV [DI], SI
                MOV SI,ES:[SI]
                INC DI
                INC DI
                JMP NXIMA

BYE:
		POPALL
		RET
MAKEIMAPTRTABLE ENDP

;------------------------------------------------------------------------
MAPLEVEL	PROC
LOCAL		SCRPTR: WORD
LOCAL		LARGEUR: BYTE
LOCAL		HAUTEUR: BYTE

		PUSHALL

		; SI = PTR SUR LE SCRIPT
                ; BX = PTR SUR DEF IMAGES
                ; DI = PTR SUR LES DEFS DU TABLEAU

		SET ES,LIBRAIRY
		SET DS,DATA

		MOV DI,0			; INIT MAPLEVEL
		MOV CX,32768/4
		MOV EAX,0
NETT:		MOV [DI],EAX
		ADD DI,4
		LOOP NETT


		MOV DX,WORD PTR SCRIPTSIZE
		MOV SI, OFFSET SCRDEFS		; INIT SI= DÉBUT SCRDEFS

NXENTREE:

                CMP WORD PTR ES:[SI], -1	; IF THE 2 FIRST BYTE
                JE BYE                          ; OF AN ENTRY ARE -1
						; THEN WE REACHED THE
                                                ; END.

		CMP BYTE PTR ES:[SI+1],0D0H	; DÉTERMINE SI L'OBJ
		JB OBJINUTILE			; A UN STATU > 0XD0

                XOR BX,BX			; INIT PTR BX
                MOV CX, ES:[SI+4]		; J'IDENTIFIE LE PTR
		OR CX,CX			; SUR L'IMAGE ASSOCIÉE
                JE PTRIMAGETROUVE		; À L'OBJET ET JE LE
NXIMAGE:					; PLACE DANS BX
                MOV BX,WORD PTR ES:[BX]
                LOOP NXIMAGE
PTRIMAGETROUVE:

						;******************
		MOV AX, WORD PTR ES:[SI+6]	; PLACE LE PTR SUR
		MOV SCRPTR,AX			; L'EMPLACEMENT DU
						; PLAN CADRILLÉ

		MOV DI,SCRPTR

		MOVB HAUTEUR, ES:[BX+4]
		MOVB LARGEUR, ES:[BX+2]
		ADD BX,6

		MOV CH, HAUTEUR			; CPT2 = HAUTEUR

L2:						; BEGIN 2
		MOV CL, LARGEUR			; CPT1 = LARGEUR


						; BEGIN 1
L1:		

		CMP WORD PTR ES:[BX],0
		JE IGNORE


                CALL WORD PTR DS:MAPLEVELEXTENSION

		CMPB BYTE PTR [DI], BYTE PTR ES:[SI+1]
		JAE IGNORE

		MOVB BYTE PTR [DI], BYTE PTR ES:[SI+1]

IGNORE:		ADD BX,2
		INC DI

		DEC CL
		OR CL,CL
		JNE L1				; END 1

		ADD SCRPTR,256
		MOV DI,SCRPTR

		DEC CH
		OR CH,CH
		JNE L2				; END 2


OBJINUTILE:
		ADD SI,8
		MOV CX,DX
		DEC DX
		LOOP NXENTREE

BYE:
		POPALL
		RET


MAPLEVEL	ENDP

;-------------------------------------------------------------------------

;IMSDEFS		DB 32768 DUP (0)
;SCRDEFS		DB 16384 DUP (0)
;SCRTEMP		DB 04096 DUP (0)
;IMSNAMES        	DB 08192 DUP (0)
;STODEFS		DB 04096 DUP (0)

TRIEROBJS PROC
		PUSHALL

                SET DS,DATA
		SET ES,LIBRAIRY
		MOV CX,WORD PTR SCRIPTSIZE
                SHR CX,3
		MOV SI,OFFSET SCRDEFS
		MOV DI,SI
		MOV BX,CHGINGDEFS

NXENTRY:
                ;JMP COPYBCK
		IFEDO BYTE PTR ES:[SI+1], 0, COPYBCK
		CMP BYTE PTR ES:[SI+1], 0D0H
		JAE COPYBCK

COPYFOW:	MOV EAX,ES:[SI]
		MOV ES:[BX],EAX
		MOV EAX,ES:[SI+4]
		MOV ES:[BX+4],EAX
		ADD BX,8
		JMP TONXENTRY

COPYBCK:	MOV EAX,ES:[SI]
		MOV ES:[DI],EAX
		MOV EAX,ES:[SI+4]
		MOV ES:[DI+4],EAX
		ADD DI,8

TONXENTRY:
		ADD SI,8
		LOOP NXENTRY
		MOV WORD PTR ES:[DI],-1
		MOV WORD PTR ES:[BX],-1
		SUB DI, OFFSET SCRDEFS
		SHR DI,3
		MOV WORD PTR SCRIPTSIZE,DI
		POPALL
		RET
TRIEROBJS ENDP

;-------------------------------------------------------------------------

DRAWBCK PROC
		PUSHALL

                ERASESEG SCREEN

                SET GS,SCREEN
                SET ES,LIBRAIRY

                MOV SI,OFFSET SCRDEFS
		CALL DRAWSCRIPT

                ;COPYSEG SCREEN,SCREEN2

		POPALL
		RET

DRAWBCK ENDP

;------------------------------------------------------------------------
DRAWFOW PROC
		PUSHALL

                ;ERASESEG SCREEN

                SET GS,0A000H
                SET ES,LIBRAIRY

                MOV SI,CHGINGDEFS
		CALL DRAWSCRIPT

                ;COPYSEG SCREEN,SCREEN2

		POPALL
		RET

DRAWFOW ENDP

;-----------------------------------------------------------------------

SCROLLRG	PROC NEAR

		PUSHALL
		SET DS,DATA
		SET GS,SCREEN

                NUL DH
		MOV DL,BYTE PTR SCRHEI
                SHL DX,3
		MOV BX,0

_2:		MOV CX,(0140H-8)/4

_1:
		MOV EAX,GS:[BX+8]
		MOV GS:[BX],EAX
		ADD BX,4

		LOOP _1

                ADD BX,8

		MOV CX,DX
		DEC DX
		LOOP _2

		PUSH WORD PTR SCRLEN
                PUSH WORD PTR MX

                NUL AH
                MOV AL,BYTE PTR SCRLEN
                DEC AL
                DEC AL
                ;SHL AX,3
                ;SHR AX,4
                SHR AX,1
                ADD AX,SCREEN
                SET GS,AX

		MOV AL, BYTE PTR MX
                ADD AL,BYTE PTR SCRLEN
                DEC AL
                MOV BYTE PTR MX,AL

                MOV BYTE PTR SCRLEN, 2


                ;XOR EAX,01010101H
                XOR EAX,EAX
                MOV DI,0

                MOV CL,BYTE PTR SCRHEI
                NUL CH
                SHL CX,3
_3:
                MOV GS:[DI+8],EAX
                MOV GS:[DI+4+8],EAX
                ADD DI,140H
                LOOP _3

                SET ES,LIBRAIRY
                MOV SI,OFFSET SCRDEFS
		CALL DRAWSCRIPT

                POP WORD PTR MX
                POP WORD PTR SCRLEN

                POPALL
                RET

SCROLLRG	ENDP
;-----------------------------------------------------------------------

SCROLLLF	PROC NEAR

		PUSHALL
		SET DS,DATA
		SET GS,SCREEN

                NUL DH
		MOV DL,BYTE PTR SCRHEI
                SHL DX,3
                MOV SI,0

_2:		MOV CX,39
		MOV BX,38*8

_1:
		MOV EAX,GS:[SI+BX]
		MOV GS:[SI+BX+8],EAX
		MOV EAX,GS:[SI+BX+4]
		MOV GS:[SI+BX+8+4],EAX
		SUB BX,8

		LOOP _1

                ADD SI,140H

		MOV CX,DX
		DEC DX
		LOOP _2

		PUSH WORD PTR SCRLEN
                PUSH WORD PTR MX

                ;NUL AH
                ;MOV AL,BYTE PTR SCRLEN
                ;DEC AL
                ;DEC AL
                ;SHL AX,3
                ;SHR AX,4
                ;SHR AX,1
                ;ADD AX,SCREEN
                ;SET GS,AX

                SET GS,SCREEN

		;MOV AL, BYTE PTR MX
                ;ADD AL,BYTE PTR SCRLEN
                ;DEC AL
                ;MOV BYTE PTR MX,AL

                DEC BYTE PTR MX
                MOV BYTE PTR SCRLEN, 1

                ;XOR EAX,01010101H
                XOR EAX,EAX
                MOV DI,0

                MOV CL,BYTE PTR SCRHEI
                NUL CH
                SHL CX,3
_3:
                MOV GS:[DI],EAX
                MOV GS:[DI+4],EAX
                ADD DI,140H
                LOOP _3

                SET ES,LIBRAIRY
                MOV SI,OFFSET SCRDEFS
		CALL DRAWSCRIPT

                POP WORD PTR MX
                POP WORD PTR SCRLEN

                POPALL
                RET

SCROLLLF	ENDP

;-----------------------------------------------------------------------
SCROLLDN	PROC NEAR

		PUSHALL
		SET DS,DATA
		SET GS,SCREEN

                NUL DH
		MOV DL,BYTE PTR SCRHEI
		MOV SI,0A00H
		MOV BX,0

_2:		MOV CX,0A00H/4

_1:
		MOV EAX,GS:[SI+BX]
		MOV GS:[BX],EAX
		ADD BX,4

		LOOP _1

		MOV CX,DX
		DEC DX
		LOOP _2

                PUSH WORD PTR SCRLEN
                PUSH WORD PTR MX

		MOV AL, BYTE PTR MY
                ADD AL,BYTE PTR SCRHEI
                MOV BYTE PTR MY,AL
                ;DEC BYTE PTR MY

                ;DEC BYTE PTR MY

                ;SET GS,SCREEN2
                MOV AL,BYTE PTR SCRHEI
                DEC AL
                MOV AH,0AH
                MUL AH
                SHL AX,8-4
                ;SHR AX,4
                ADD AX,SCREEN
                SET GS,AX

                MOV CX,0A00H/4
                MOV EAX,0
                MOV DI,0

_3:             MOV GS:[DI],EAX
                ADD DI,4
                LOOP _3

                ;FILLMEM GS,0,0A00H,3

                MOV BYTE PTR SCRHEI,1
                SET ES,LIBRAIRY

                MOV SI,OFFSET SCRDEFS
		CALL DRAWSCRIPT

                POP WORD PTR MX
		POP WORD PTR SCRLEN

                ;COPYSEG SCREEN,SCREEN

		POPALL
		RET
SCROLLDN	ENDP

;-------------------------------------------------------------------------

SCROLLUP	PROC

		PUSHALL
		SET DS,DATA
		SET GS,SCREEN

                NUL DH
		MOV DL,BYTE PTR SCRHEI
		MOV SI,0A00H
		MOV BX,0

                MOV AL,BYTE PTR SCRHEI
                DEC AL
                MOV AH,0AH
                MUL AH
                SHL AX,8
		MOV BX,AX


_2:		MOV CX,0A00H/4

_1:
		MOV EAX,GS:[BX-0A00H]
		MOV GS:[BX],EAX
		ADD BX,4

		LOOP _1

                SUB BX,0A00H*2

		MOV CX,DX
		DEC DX
		LOOP _2


                PUSH WORD PTR SCRLEN
                PUSH WORD PTR MY

		DEC BYTE PTR MY
                MOV BYTE PTR SCRHEI,1

                SET GS,SCREEN
                SET ES,LIBRAIRY

                MOV CX,0A00H/4
                MOV EAX,0
                MOV DI,0

_3:             MOV GS:[DI],EAX
                ADD DI,4
                LOOP _3

                ;FILLMEM GS,0,0A00H,3

                MOV SI,OFFSET SCRDEFS
		CALL DRAWSCRIPT

                POP WORD PTR MY
		POP WORD PTR SCRLEN

                ;COPYSEG SCREEN,SCREEN2

		POPALL
		RET

SCROLLUP	ENDP

;-----------------------------------------------------------------------
SLOWDOWN 	PROC
		PUSHALL

                PUSH WORD PTR SCRLEN
                PUSH WORD PTR MY

		;DEC BYTE PTR MY
                MOV BYTE PTR SCRHEI,1

                SET GS,SCREEN
                SET ES,LIBRAIRY

                MOV CX,0A00H/4
                MOV EAX,0
                MOV DI,0

_3:             MOV GS:[DI],EAX
                ADD DI,4
                LOOP _3

                ;FILLMEM GS,0,0A00H,3

                MOV SI,OFFSET SCRDEFS
		CALL DRAWSCRIPT

                POP WORD PTR MY
		POP WORD PTR SCRLEN

                POPALL
                RET

SLOWDOWN	ENDP

;-----------------------------------------------------------------------
; RETURN VALUE: AX= IMAGE NUMBER;
_FINDLEADINGCHAR PROC NEAR PASCAL, CAR:BYTE
LOCAL		CHARPTR:WORD

		PUSH ES
                PUSH SI

		SET ES,LIBRAIRY
                MOV SI,OFFSET IMSNAMES

                XOR AX,AX
LOOK:           CMPB BYTE PTR ES:[SI],CAR
                JE FOUND
                MOV CHARPTR,SI
                SKIPCHAR LIBRAIRY,CHARPTR, 13
                MOV SI,CHARPTR
		INC AX
                LOOP LOOK
FOUND:

		POP SI
                POP ES
                RET
_FINDLEADINGCHAR ENDP
;-----------------------------------------------------------------------







;-----------------------------------------------------------------------
; DRAWSCRIPT:
; CETTE PROCÉDURE EFFECTUE UNE RÉIMPRESSION TOTALE DE L'ÉCRAN À PARTIR
; DU SCRIPT MAÎTRE.
; PARAMÈTRE D'ENTRÉE:
; SI : OFFSET DE LA LIBRAIRIE (POINT D'ENTRÉE DU SCRIPT MAÎTRE)
;-----------------------------------------------------------------------
DRAWSCRIPT PROC
                PUSHALL
		SET ES,LIBRAIRY
		IFEDO WORD PTR ES:[SI], -1, ENDOFSCR
                CALL SCRIPTEXEC

ENDOFSCR:       POPALL
		RET

DRAWSCRIPT ENDP

;-----------------------------------------------------------------------
; _DRAWENTRY:
; CETTE PROCÉDURE DESSINE SUR L'ÉCRAN UNE ENTRÉE PRÉCISE DU SCRIPTE
; MAÎTRE.
; PARAMÈTRE D'ENTRÉE:
; ENTRY: POINT D'ENTRÉE SUR LE SCRIPT MAÎTRE.
;-----------------------------------------------------------------------
_DRAWENTRY   	PROC NEAR PASCAL, ENTRY:WORD
CHKNXENTRY:
                PUSHALL
                MOV SI,ENTRY
                SET DS,DATA
                SET ES,LIBRAIRY
                SET GS,0A000H
                MOV DX,WORD PTR MX
                MOV AX,ES:[SI+6]		; AL=OBJX, AH=OBJY

                ; CHANGEMENT 16 MAI 1995
                ;XOR BX,BX
                ;MOV CX,WORD PTR ES:[SI+4]	; CURRENTIMA
                ;JCXZ FOUNDIMAPTR

CHKNXIMA:       ;MOV BX,ES:[BX]
                ;LOOP CHKNXIMA

                FINDIMAPTR


FOUNDIMAPTR:	MOV CL,ES:[BX+2]		; CL=OBJ LENGHT
		MOV CH,ES:[BX+4]		; CH=OBJ HEIGHT

                MOV LX,BX
		MOV BX,DX			; BL= MX; BH=MY

		; OX+OL >= MX
		ADD AL,CL
                CMP AL,BL
                JB ITISOVER

                ; OX <= MX+40
                ADD BL,BYTE PTR SCRLEN
		SUB AL,CL
                CMP AL,BL
                JA ITISOVER

                ; OY+OH >= MY
                ADD AH,CH
                CMP AH,BH
                JB ITISOVER

                ; OY <= MY+40
		ADD BH,BYTE PTR SCRHEI
                SUB AH,CH
                CMP AH,BH
                JA ITISOVER

;*****************************************************************

		PUSH BP
		MOV BX,LX

TROUVEIMAPTR:   SET HX, WORD PTR ES:[BX+4]
		SET LX, WORD PTR ES:[BX+2]

                MOV DX, WORD PTR ES:[SI+6]

                ADD BX, 6

SC2:						; ** BEGIN 2
                MOV CX,LX			; ** BEGIN 1

SC1:

                MOV AX, ES:[BX]			; FONT
                OR AX,AX
                JE BLANKIMA

                PUSH DX

                SUB DL,BYTE PTR MX
                CMP DL,BYTE PTR SCRLEN
                JAE NOTONSCREEN_

                SUB DH,BYTE PTR MY
		CMP DH,BYTE PTR SCRHEI
                JAE NOTONSCREEN_

                PUSH BX

                MOV BP,FONT
ISINSEG_:       CMP AX,1024
                JB INTHISSEG

                SUB AX,1024
		ADD BP,65536/16
                JMP ISINSEG_

INTHISSEG:	SHL AX,6
                MOV BX,AX
                MOV FS,BP

                MOV AX,DX
             	XOR DH,DH
                SHL DX,3
                MOV DI,DX

                ; AJOUTÉ UNE OFFSET ICI!	; 27 AVRIL 1995
                ADD DI,WORD PTR DRAWOFFSET

                MOV AL,0AH
                MUL AH
                SHL AX,8
                ADD DI,AX

                PUSH CX

		;------------------------------------------------
                ; THIS INSIDE ZONE WAS MODIFIED ON 02-11-95
                ;------------------------------------------------

                MOV DX,8
NXLINE:         MOV CX,2

NXPIX:
		MOV EAX,FS:[BX]

		OR AX,AX
                JE NULAX

                OR AL,AL
                JNE NNUL1

                MOV AL,BYTE PTR GS:[DI]

NNUL1:		OR AH,AH
                JNE NNUL2

                MOV AH,BYTE PTR GS:[DI+1]

NNUL2:		MOV GS:[DI],AX
NULAX:
		SHR EAX,16
                OR AX,AX
                JE NULAX2

		OR AL,AL
                JNE NNUL3

                MOV AL,BYTE PTR GS:[DI+2]

NNUL3:		OR AH,AH
		JNE NNUL4

                MOV AH,BYTE PTR GS:[DI+3]

NNUL4:		MOV GS:[DI+2],AX
NULAX2:

		ADD BX,4
                ADD DI,4
                LOOP NXPIX

                ADD DI,140H-8
                MOV CX,DX
                DEC DX
                LOOP NXLINE

		;--------------------------------------------

                POP CX

		POP BX
NOTONSCREEN_:	POP DX

BLANKIMA:       ADD BX,2
                INC DL
                ELOOP SC1            		; ** END 1

		MOV DL,BYTE PTR ES:[SI+6]
                INC DH
                MOV CX,HX
                DEC HX
                ELOOP SC2                        ; ** END 2

;**********************************************************************

		POP BP

ITISOVER:	ADD SI,8
		;IFEDO WORD PTR ES:[SI],-1,ENDOFSCR
                ;JNE CHKNXENTRY

ENDOFSCR:       ;MOV WORD PTR ES:[DI],-1

                POPALL
                RET
_DRAWENTRY ENDP



;-----------------------------------------------------------------------

SCRIPTEXEC PROC
                ;MOV BP,DX
                ;IFEDO BP,0,ENDOFSCR


CHKNXENTRY:
                MOV DX,WORD PTR MX
                MOV AX,ES:[SI+6]		; AL=OBJX, AH=OBJY


                ; CHANGEMENT 16 MAI 1995
                ;XOR BX,BX
                ;MOV CX,WORD PTR ES:[SI+4]	; CURRENTIMA
                ;JCXZ FOUNDIMAPTR

CHKNXIMA:       ;MOV BX,ES:[BX]
                ;LOOP CHKNXIMA

                FINDIMAPTR


FOUNDIMAPTR:	MOV CL,ES:[BX+2]		; CL=OBJ LENGHT
		MOV CH,ES:[BX+4]		; CH=OBJ HEIGHT

                MOV LX,BX
		MOV BX,DX			; BL= MX; BH=MY

		; OX+OL >= MX
		ADD AL,CL
                CMP AL,BL
                JB ITISOVER

                ; OX <= MX+40
                ADD BL,BYTE PTR SCRLEN
		SUB AL,CL
                CMP AL,BL
                JA ITISOVER

                ; OY+OH >= MY
                ADD AH,CH
                CMP AH,BH
                JB ITISOVER

                ; OY <= MY+40
		ADD BH,BYTE PTR SCRHEI
                SUB AH,CH
                CMP AH,BH
                JA ITISOVER

;*****************************************************************

		PUSH BP
		MOV BX,LX

TROUVEIMAPTR:   SET HX, WORD PTR ES:[BX+4]
		SET LX, WORD PTR ES:[BX+2]

                MOV DX, WORD PTR ES:[SI+6]

                ADD BX, 6

SC2:						; ** BEGIN 2
                MOV CX,LX			; ** BEGIN 1

SC1:

                MOV AX, ES:[BX]			; FONT
                OR AX,AX
                JE BLANKIMA

                PUSH DX

                SUB DL,BYTE PTR MX
                CMP DL,BYTE PTR SCRLEN
                JAE NOTONSCREEN_

                SUB DH,BYTE PTR MY
		CMP DH,BYTE PTR SCRHEI
                JAE NOTONSCREEN_

                PUSH BX

                MOV BP,FONT
ISINSEG_:       CMP AX,1024
                JB INTHISSEG

                SUB AX,1024
		ADD BP,65536/16
                JMP ISINSEG_

INTHISSEG:	SHL AX,6
                MOV BX,AX
                MOV FS,BP

                MOV AX,DX
             	XOR DH,DH
                SHL DX,3
                MOV DI,DX

                ; AJOUTÉ UNE OFFSET ICI!	; 27 AVRIL 1995
                ADD DI,WORD PTR DRAWOFFSET

                MOV AL,0AH
                MUL AH
                SHL AX,8
                ADD DI,AX

                PUSH CX

		;------------------------------------------------
                ; THIS INSIDE ZONE WAS MODIFIED ON 02-11-95
                ;------------------------------------------------

                MOV DX,8
NXLINE:         MOV CX,2

NXPIX:
		MOV EAX,FS:[BX]

		OR AX,AX
                JE NULAX

                OR AL,AL
                JNE NNUL1

                MOV AL,BYTE PTR GS:[DI]

NNUL1:		OR AH,AH
                JNE NNUL2

                MOV AH,BYTE PTR GS:[DI+1]

NNUL2:		MOV GS:[DI],AX
NULAX:
		SHR EAX,16
                OR AX,AX
                JE NULAX2

		OR AL,AL
                JNE NNUL3

                MOV AL,BYTE PTR GS:[DI+2]

NNUL3:		OR AH,AH
		JNE NNUL4

                MOV AH,BYTE PTR GS:[DI+3]

NNUL4:		MOV GS:[DI+2],AX
NULAX2:

		ADD BX,4
                ADD DI,4
                LOOP NXPIX

                ADD DI,140H-8
                MOV CX,DX
                DEC DX
                LOOP NXLINE

		;--------------------------------------------

                POP CX

		POP BX
NOTONSCREEN_:	POP DX

BLANKIMA:       ADD BX,2
                INC DL
                ELOOP SC1            		; ** END 1

		MOV DL,BYTE PTR ES:[SI+6]
                INC DH
                MOV CX,HX
                DEC HX
                ELOOP SC2                        ; ** END 2

;**********************************************************************

		POP BP

ITISOVER:	ADD SI,8
		IFEDO WORD PTR ES:[SI],-1,ENDOFSCR
                JNE CHKNXENTRY

ENDOFSCR:       ;MOV WORD PTR ES:[DI],-1

		RET
SCRIPTEXEC ENDP

CODE ENDS
END
