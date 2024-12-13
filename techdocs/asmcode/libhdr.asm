;----------------------------------------------------------------
;       LIBRAIRY HEADER FOR LIBMAKER V1.0
;       by Francois Blanchette
;----------------------------------------------------------------

;----------------------------------------------------------------
ASSUME CS:CODE,DS:DATA,SS:STACK
STACK     SEGMENT STACK
	  DB 400H DUP  (0)
STACK     ENDS
;----------------------------------------------------------------

;----------------------------------------------------------------
DATA      SEGMENT
COPYRIGHT      db "LIBRAIRY HEADER: (C) 1994 FRANCOIS BLANCHETTE"
PATH           db 0
PSP	       db 128 DUP (0)
FILENAME       db 32 DUP (0)
MOUSE_DOWN     db "Warning: missing mouse and/or driver.$"
FILES_DOWN     db "Warning: missing or modified file.$"
PAUSE_TEXT     db "Press [space] to continue playing...    $"
GIVE_NAME_TEXT db "Requiered .LIB filename on command line$"
LIB_EXT	       db ".lib",0,"$"
FNT_EXT	       db ".fnt",0,"$"

align 2
HEADER 	       db 4 DUP (0)
OLD_VIDEO_MODE db 3

DATA   ENDS
;----------------------------------------------------------------
FONTS SEGMENT
DB 65535 DUP (0)
FONTS ENDS

MEM2 SEGMENT
MEM2 ENDS

;----------------------------------------------------------------
CODE SEGMENT READONLY PUBLIC 'CODE'
VLAMITS  PROC NEAR
;----------------------------------------------------------------

.386

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
		mov [di],al

		inc si
		inc di
		loop XTRSN

		mov di,offset PSP
		add di,bx
		inc di

		mov si,offset LIB_EXT
		push di
		call EXT			; Add extension to filename

		mov dx,DATA
		mov ds,dx
		mov es,dx
		mov dx,offset PSP+2
		mov bx,offset HEADER
		mov cx,4
		call LOADNEW
		jmp PREPARE

GIVE_CM_LINE:   mov dx,DATA
		mov ds,dx
		mov dx,offset GIVE_NAME_TEXT
		mov ah,9
		int 21h
		mov ah,4ch
		int 21h

PREPARE:        ; OUVERTURE DE ?.LIB
		mov dx,DATA
		mov ds,dx
		mov dx,offset PSP+2
		mov al,0
		mov ah,3dh		; LECTURE
		int 21h
		jc NOT_FOUND

		mov bp,ax		; BP=CODE D'ACCÈS
		mov bx,ax

		mov dx,DATA
		mov ds,dx
		mov si,offset HEADER

		mov cx,0
		mov dx,[si+2]		; Déplace le pointeur de DX
		mov al,0		; relatif au début du fichier
		mov ah,42h		; Déplace pointeurs
		int 21h
		jc NOT_FOUND

		; LECTURE DES FONTS
		mov dx,DATA
		mov ds,dx
		mov si,offset HEADER

		mov cx,[si]
		rol cx,6
		mov dx,FONTS
		mov ds,dx
		mov dx,0

		mov bx,bp
		mov ah,3fh
		int 21h
		jc NOT_FOUND

		; FERMETURE
		mov bx,bp
		mov ah,3eh
		int 21h
		jc NOT_FOUND

		call CONVENSIONS
		pop di
		mov si,offset FNT_EXT
		call EXT

		; CRÉE UN FICHIER
		mov dx,DATA
		mov ds,dx
		mov dx,offset PSP+2
		mov cx,0
		mov ah,3ch
		int 21h

		mov bx,ax
		mov bp,ax

		call CONVENSIONS
		mov si,offset HEADER
		mov cx,[si]
		rol cx,6


		mov dx,FONTS
		mov ds,dx
		mov dx,0
		mov ah,40h
		int 21h

		mov bx,bp
		mov ah,3eh
		int 21h

		jmp QUIT

		call CONVENSIONS





		mov si,offset HEADER
		mov ax,[si+2]



		jmp QUIT

		;----------------------------------------------
		; EXT:
		; INPUTS:
		; [si] source of extension
		; [di] destination of extension
		;-----------------------------------------------

EXT:	       	pusha
		mov cx,6
EXT_:	       	mov al,[si]
		mov [di],al
		inc si
		inc di
		loop EXT_
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
	       mov dx,FONTS
	       mov es,dx
	       ;mov dx,MEM2
	       ;mov fs,dx
	       ;mov dx,0a000h
	       ;mov gs,dx
	       pop dx
	       ret


	       ;-------------------------------------------------
	       ; QUIT / NOT_FOUND
	       ; INPUTS:
	       ; no inputs
	       ; OUTPUTS:
	       ; nothing/Warning: missing or write protected file
	       ;-------------------------------------------------

QUIT:          mov ah,1
	       ;int 21h

	       mov dx,DATA
	       mov ds,dx
	       mov si,offset OLD_VIDEO_MODE
	       xor ax,ax
	       mov al,[si]
	       ;int 10h
	       xor al,al
	       mov ah,4ch    ; retourne au DOS
	       int 21h

NOT_FOUND:     mov dx,DATA
	       mov ds,dx
	       mov si,offset OLD_VIDEO_MODE
	       xor ax,ax
	       mov al,[si]
	       ;int 10h
	       mov ah,9
	       mov dx,DATA
	       mov ds,dx
	       mov dx,offset FILES_DOWN
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

		    ;-----------------------------------------
		    ; GETAX
		    ; INPUTS:
		    ; no inputs
		    ; OUTPUS:
		    ; return a caracter from the buffer
		    ;-----------------------------------------

GETAX:              call NUM_LOCK
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


; -----------------------FIN DU PROGRAMME-----------------------
VLAMITS    ENDP                           ; Fin de la procedure
CODE ENDS                                ; Fin du programme
END     VLAMITS                           ; Point d'entree
;---------------------------------------------------------------
