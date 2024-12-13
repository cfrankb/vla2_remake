; ****************************************************************
;
; 	ASSEMBLY MODULES RUNTIME LIBRAIRY: 94STATV2.ASM
;
; 		COPYRIGHT 1994 FRANCOIS BLANCHETTE
;
; ****************************************************************

ASSUME SS:STACK, DS:DATA, ES:LIBRAIRY

TITLE RUNTIME_LIBRAIRY_94STATV2

INCLUDE \MASM61\LISTING\SSFSM95.INC
INCLUDE \MASM61\LISTING\IOSYSTEM.INC

USEREPV2	; 94REPV2.ASM

PUBLIC IMSDEFS, IMSNAMES
PUBLIC STODEFS, SCRDEFS, SCRTEMP
PUBLIC MX,MY
PUBLIC SCRIPTSIZE, BKCOLOR

PUBLIC LOADIMS, DRAWSCREEN
PUBLIC DRAWSOMESCREEN, ERASESCREEN
PUBLIC SCRLEN, SCRHEI
PUBLIC LOADSCR

STACK     SEGMENT STACK
STACK     ENDS

DATA SEGMENT 'DATA' PUBLIC

COPYRIGHT	DB "94STATV2 RUNTIME LIBRAIRY "
		DB "(C) 1994 FRANCOIS BLANCHETTE."

;ALIGN 2
MX		DB 0
MY 		DB 0
SCRLEN		DB 40
SCRHEI		DB 25

;ALIGN 4
BKCOLOR		DD 0
SCRIPTSIZE	DW 0

DATA ENDS

LIBRAIRY SEGMENT PUBLIC 'LIBRAIRY'
IMSDEFS		DB 32768 DUP (0)
SCRDEFS		DB 16384 DUP (0)
SCRTEMP		DB 04096 DUP (0)
IMSNAMES        DB 08192 DUP (0)
STODEFS		DB 04095 DUP (0)
LIBRAIRY ENDS

FONT SEGMENT PUBLIC 'FONT'
DB 65535 DUP (4)
FONT ENDS

FONT2 SEGMENT PUBLIC 'FONT2'
DB 65535 DUP (5)
FONT2 ENDS

FONT3 SEGMENT PUBLIC 'FONT3'
DB 65535 DUP (6)
FONT3 ENDS

FONT4 SEGMENT PUBLIC 'FONT4'
DB 65535 DUP (7)
FONT4 ENDS

SCREEN SEGMENT 'SCREEN' PUBLIC
DB 65535 DUP (0)
SCREEN ENDS

CODE SEGMENT 'CODE' PUBLIC

.386

;------------------------------------------------------------------------

LOADIMS PROC

		HLOADIMS <DX>
                RET

LOADIMS ENDP

;------------------------------------------------------------------------

LOADSCR PROC

		PUSHALL

                SUB SP,4
                MOV BP,SP

                HOPENFORREAD <DX>, WORD PTR [BP+2]
                HREADFILE STACK, BP, 2, WORD PTR [BP+2]

                ; PASSE 16 OCTETS..
                MOV AH,42H
                MOV BX,WORD PTR [BP+2]
                MOV AL,1	; RELATIF À L'EMPLACEMENT ACTUEL
                NUL CX
                MOV DX,16
                INT 21H
                JCERROR

                HREADFILE LIBRAIRY,OFFSET SCRDEFS,WORD PTR[BP],WORD PTR[BP+2]
		HCLOSE WORD PTR [BP+2]

                MOVW WORD PTR SCRIPTSIZE, WORD PTR [BP]

                ADD SP,4
		POPALL
                RET

LOADSCR ENDP

;------------------------------------------------------------------------

DRAWSCREEN PROC

		PUSHALL
		MOV EAX,DWORD PTR BKCOLOR
                XOR DI,DI
                SET GS,SCREEN
                MOV CX,65536/4

FILLBK:         MOV GS:[DI],EAX
                ADD DI,4
		LOOP FILLBK

                SET ES,LIBRAIRY

                MOV DX, WORD PTR SCRIPTSIZE
                SHR DX,3

                MOV SI,OFFSET SCRDEFS

                MOV BP,DX
                IFEDO BP,0,ENDOFSCR


CHKNXENTRY:
                MOV DX,WORD PTR MX
                MOV AX,ES:[SI+6]		; AL=OBJX, AH=OBJY

                XOR BX,BX
                MOV CX,WORD PTR ES:[SI+4]	; CURRENTIMA
                JCXZ FOUNDIMAPTR

CHKNXIMA:       MOV BX,ES:[BX]
                LOOP CHKNXIMA

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
		MOV CX,BP
		DEC BP
                ELOOP CHKNXENTRY

ENDOFSCR:       ;MOV WORD PTR ES:[DI],-1

                POPALL
                RET


DRAWSCREEN ENDP
;-----------------------------------------------------------------------

; THE PROCEDURE ERASESCREEN WAS ORIGINALLY USED IN THE STATLB.ASM MODULE
; THAT SERVICE THE STATICS V1 SYSTEM. BUT, I CHOOSE TO INCLUDE IT HERE
; SO IT COULD SERVICE THE NEW PROGRAMS AS WELL.

ALIGN 2
ERASESEQ	DW 8,0,1,6,2,5,3,7,4

ERASESCREEN PROC NEAR

		PUSHALL

		MOV DX,0A000H
		MOV GS,DX
		MOV DX,SCREEN
		MOV ES,DX
		MOV AL,0
		MOV SI,0
		MOV BX,0

		MOV BP,2
MANIACLAPX_:	MOV CX,65536

DODRAWSCREEN_:  MOV DI,SI
		ADD DI,CS:[BX+OFFSET ERASESEQ]
		INC BX
		INC BX
		CMP BX,10 +4
		JNE XNULBXAT_
		MOV BX,0
XNULBXAT_:

		MOV AL,0
		MOV GS:[DI],AL
		ADD SI,5+7

		PUSH CX
		MOV CX,64/4
WAITFORCORRINE_:LOOP WAITFORCORRINE_
		POP CX
		LOOP DODRAWSCREEN_

		MOV CX,BP
		DEC BP
		LOOP MANIACLAPX_

                POPALL
		RET
ERASESCREEN ENDP

		;-----------------------

; THE PROCEDURE DRAWSOMESCREEN WAS ORIGINALLY USED IN THE STATLB.ASM MODULE
; THAT SERVICE THE STATICS V1 SYSTEM. BUT, I CHOOSE TO INCLUDE IT HERE
; SO IT COULD SERVICE THE NEW PROGRAMS AS WELL.

DRAWSOMESCREEN	PROC NEAR

 		;MOV CX,50
		;CALL PAUSE

                PUSHALL

		MOV DX,0A000H
		MOV GS,DX
		MOV DX,SCREEN
		MOV ES,DX
		MOV AL,0
		MOV SI,0
		MOV BX,0


		MOV BP,2
MANIACLAPX:	MOV CX,65536

DODRAWSCREEN:  	MOV DI,SI
		ADD DI,CS:[BX+OFFSET ERASESEQ]
		INC BX
		INC BX
		CMP BX,10 +4
		JNE XNULBXAT
		MOV BX,0
XNULBXAT:

		MOV AL,ES:[DI]
		MOV GS:[DI],AL
		ADD SI,5+7

		PUSH CX
		MOV CX,64/4
WAITFORCORRINE: LOOP WAITFORCORRINE
		POP CX
		LOOP DODRAWSCREEN

		MOV CX,BP
		DEC BP
		LOOP MANIACLAPX

                POPALL

		RET

DRAWSOMESCREEN ENDP

;------------------------------------------------------------------------

CODE ENDS
END
