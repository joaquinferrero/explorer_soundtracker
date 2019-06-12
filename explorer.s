*
* 11/5/93 20:34
*
* TABULADOR A 16 CARACTERES!!!!
*
* Explorer Soundtracker 4 canales.
* Joaquin Ferrero. Mayo 1993. Color y monocromo.
* Demo Loop: Lee todos los m¢dulos presentes en secuencia, con 2
* modos de tocarlos: normal y en loop.
*
* V3.0  Primera versi¢n. Deriva del JFSTE25 V2.72.
* V3.1  Versi¢n con control de volumen para Mega STe.
* V3.11 Se corrigi¢ error de Slide_Volumen y galleta de tipo m quina
*       para admitir al TT. Se modific¢ el listado para hacer versiones
*       espec¡ficas para cada m quina.
* V3.12 Se termin¢ de corregir el error del Slide Volume. Ahora ya se
*       oye todo el efecto correctamente. Adem s se corrigi¢ el error
*       de tocar de nuevo el sonido si s¢lo estaba presente el # de
*       instrumento; ahora, sube el volumen al original.
* V3.14 Nueva version para STe. Ya funciona el efecto de volumen, a
*       consta de cambiar los vumetros (nueva rutina instalada al final
*       de la rutina Amiga). Corregido velocidad 0. Se recupera la anterior
*       paleta de colores. La rutina Amiga se meti¢ dentro del Timer A
*       (un bra.s menos). Se cambi¢ tune a $5D. Se cambi¢ adda.l por lea's.
*       Se cambia bien el color del texto en monocromo. Corregido el error
*       de cambio de velocidad siempre a 6 cuando hay repetici¢n.
* V3.15 Corregido el error de vol£menes fuera del rango $00-$40. Instalado
*       el efecto de Tr‚molo (7). Se cambi¢ tune a $5C. V£metros cambiados.
*       Efecto Ping_Pong. Lectura del comando. 50Khz. Una sola versi¢n.
*
*       =====>>>>>ESTA ES LA ULTIMA VERSION EJECUTABLE<<<<<=====
*
*
* VFalcon	ESTO ES UNA VERSION DE PRUEBA QUE SOLO FUNCIONA EN LOS MODOS
*	COMPATIBLES ST (COLOR Y MONOCROMO) DE UN FALCON!!!
*	NO ESTA EN ABSOLUTO ACABADA!!!
*	NO ES COMPATIBLE PROTRACKER, AUNQUE PUEDE LEER LOS MODS
*
* REVISAR VIBRATO $400.
* FALTA COMPROBADA: VOLVER A TOCAR INSTRUMENTO CON S¢LO COMANDO DE VOLUMEN:
* ¨DEPENDE DEL SOUNDTRACKER?
*
* REVISAR EL MODO DE LEER LAS PARTITURAS PARA PERMITIR $7F.
*
* Los !!! indican lineas que no se ejecutan en modo residente
*********************************************** Opciones de ensamblado
	OPT	O1+
	OPT	OW1+
	OPT	O3+
	OPT	OW3+
	OPT	O4+
	OPT	OW4+
	OPT	O5+
	OPT	OW5+
	OPT	O6+
	OPT	OW6+
*	OPT	x+	Volcado de grandes etiquetas
*	OPT	a+	Optimizar a (PC)

***********************************************	Definiciones
	include atari_st.s

*************************************************
* Versi¢n para cada m quina: TT, STe y MEGASTe	*
* (que es un STe a 16Mhz.)		*
* Versi¢n en color		*
* Si color esta a 1, es la versi¢n para color	*
* Si esta a cero, es para monocromo	*
*************************************************
_MODO_B_Y_N	equ	0
_MODO_COLOR	equ	1
*COLOR	equ	_MODO_B_Y_N

*********************************************** Fichero de salida
	OUTPUT EXPLORER.TTP

	COMMENT HEAD=1		Carga r pida

********************************************** Varias definiciones
_FRQ	equ	3	Frecuencia por defecto
NDATSAM 	equ	6	# de datos para chip DMA

*********************************************** Par metros del programa
*	IFNE COLOR
*ANCHO	equ	160	Ancho f¡sico de la pantalla
*HIGHV	equ	64	Altura f¡sica de los v£metros
*ALTOV	equ	2	Tama¤o de cada nivel
*	ELSEIF
*ANCHO	equ	80
*HIGHV	equ	128
*ALTOV	equ	4
*	ENDC

VBRE	equ	7	Cada cu ntas VBLs caes los v£metros
VBLS	equ	10	Cada cu ntas interrupciones verticales
CAIDA	equ	2	Factor de caida de los v£metros
FACTVU	equ	2
*************************************************
* ALTOV >= 2: Tama¤o de los niveles	*
* HIGHV / ALTOV : N£mero de niveles	*
* 128 / NIVELES : Factor de divisi¢n	*
* FACTVU = LOG2(Factor de divisi¢n) (Para rotar)*
*************************************************

*********************************************** Buffers
FRAMES	equ	2	Cu ntos buffers y de qu‚ tama¤o
LFRAME_0	equ	126
LFRAME_1	equ	250
LFRAME_2	equ	500
LFRAME_3	equ	1002

*********************************************** Macros

****************	Averiguar direcci¢n de barra en pantalla
BARRA_alta	macro
	movea.l a2,a0		Pantalla
	adda.l #\1*80*2+(\2/(80/10))*2,a0
	move.l a0,\3		Posici¢n barra en pantalla
	endm

****************	Averiguar direcci¢n de barra en pantalla
BARRA_color	macro
	movea.l a2,a0		Pantalla
	adda.l #\1*160+(\2/(160/10))*8,a0
	move.l a0,\3		Posici¢n barra en pantalla
	endm

****************	Bucle de espera seg£n el timer D
WAITESP	macro
	clr waitc
	Jenabint #TIMED
.relop	cmp #50*\1,waitc	Segundos
	bls.s .relop
	Jdisint #TIMED
	endm

****************	Crea tablas para pintar texto
POSIC	macro
	dc.b ESC,'Y',32+\2,32+\1,0
	endm

*********************************************** Programa principal
	TEXT

_START0	bra.s _START
	tst d6		'JF'
	dc.b "Joaquin Ferrero "
	dc.b "Explorer Systems"
	dc.b " -> Mayo 1993 <-"
_START	move.l 4(sp),_basepage	Guardar
	Inicializa STACK	Reserva memoria de programa
	bne.s _Go_Out		mal, acabar
	bsr.s _test_maquina	Ver tipo de ordenador
	tst d7
	beq.s _Go_Out		Alg£n desconocido

	cmp #_MCH_TT,ex_machine
	blt.s .sigue
	lea speed_DMA(pc),a0
	move speed_DMA_TT,(a0)	Por defecto en TT y superior

.sigue	bsr _comandar		Interpretar l¡nea de comandos
	bsr _inicializar	Inicializar
	bsr _main
	tst ex_residente
	bne.s .rex
	bsr _recuperar		!!!
	bra.s _Go_Out

.rex	move.l largo_programa(pc),d0	!!!
	add.l #_ex_fin,d0	!!!
	sub.l _basepage(pc),d0	!!!

_Go_Out	tst ex_residente
	beq.s .sigue
	Ptermres d0,#0		Terminar el programa !!!
.sigue	Pterm0		!!!
***********************************************
_test_maquina:

****************	Ver la versi¢n del ordenador: NO
****************	Ver la jarra de galleta
	Super

	movea.l _p_cookies.w,a0	Direcci¢n de la Jarra
	cmpa.l #0,a0		Hay Jarra?
	beq .mal_maquina	No, no hay
	movea.l a0,a1
	move.l #"_SND",d0	Buscar configuraci¢n sonido
	bsr buscar_cookie
	tst d7
	beq .mal_maquina	No hay galleta!!
	btst #1,d0		Chip DMA
	beq .mal_maquina	No hay!!
	move.l #"_MCH",d0	Buscar tipo m quina
	bsr buscar_cookie
	tst d7
	beq .mal_maquina	No hay galleta!!
	move.l d0,ex_machine
	move.l d0,d5		Subversi¢n
	swap d0
	move d0,d7		Versi¢n

****************	Resoluciones
	Getrez		Ver resoluci¢n actual
	move d0,ex_resolucion	Guardar resoluci¢n
	cmp #_MCH_TT,d7		Un TT?
	bne.s .ver_si_STe
	cmp #6,d0		Es TT alta?
	beq .mal_pantalla	Si, un error
	bra.s .ver_color	No, pasar a baja

.ver_si_STe	cmp #_MCH_STe,d7	Es del tipo STe?
	bne.s .superior		No. ¨Falcon?
	cmp #_MCH_MEGASTe,d5	Es un MegaSTe?
	beq.s .poner_cache
.si_STe	lea _STE_1(pc),a0	s¡ es un STe
	move #$4E71,(a0)	Nop
	lea _STE_2(pc),a0
	move #$4E71,(a0)	Nop
	lea _STE_3(pc),a0
	move #$4E71,(a0)	Nop
	lea _STE_4(pc),a0
	move #$4E71,(a0)	Nop
	bra.s .ver_color
.poner_cache	SI_CACHE		Activar el cache
	bra.s .ver_color
.superior	cmp #_MCH_STe,d7	Fin lmente, ver si >STe
	blt.s .mal_maquina
.ver_color	cmp #2,d0		Ver que no es Alta
	bne.s .baja
****************	Asignar la resoluci¢n actual
.alta	move #_MODO_B_Y_N,ex_color
	bra.s .bien
.baja	move #_MODO_COLOR,ex_color

****************	Salir, con c¢digo de retorno
.bien	moveq #1,d7
.acabar	User
	rts
.mal	clr.l d7
	bra.s .acabar

****************	Informar del error
.mal_maquina	Cconws_p error0(pc)
	Cconws_p error_maquina(pc)	Mala m quina
	bra.s .sigue_error
.mal_pantalla	Cconws_p error0(pc)
	Cconws_p error_pantalla(pc)	Mala resoluci¢n
.sigue_error	Cconws_p error1(pc)
	Cconin
	bra.s .mal

****************	Subrutina de buscar una galleta
buscar_cookie	movea.l a1,a0
.sigue	tst.l (a0)		Parar si no hay m s
	bne.s .buscar
.no_encontrado	clr.l d7
	rts
.buscar	cmp.l (a0)+,d0		Encontrado?
	bne.s .next
	move.l (a0),d0		Valor de la galleta
.encontrado	moveq #1,d7
	rts
.next	addq.l #4,a0		Siguiente galleta
	bra.s .sigue

***********************************************	Interpretar l¡nea de comandos
_comandar
	Fsetdta #DT		Instalar direcci¢n del DTA

	movea.l _basepage(pc),a6	Apuntar a Basepage
	lea CMDLINE(a6),a6	Apuntar a l¡nea de comandos
	tst.b (a6)
	beq .copy_como		No hay l¡nea

	lea _comando(pc),a0
	movea.l a6,a1
	moveq #0,d0
	move.b (a1)+,d0
.lpwer	move.b (a1)+,(a0)+	Copiar comando a _comando
	dbeq d0,.lpwer

****************	Buscar modificadores '-'
	movea.l a6,a5
	clr.l d0
	move.b (a5)+,d0		Longitud
.loop_cmd	cmp.b #'-',(a5)+	Buscar par metro
	dbeq d0,.loop_cmd
	tst d0
	bmi.s .a		Se acab¢

	clr d0
	move.b (a5),d0		Leerlo
	subq.l #1,a5
	move.b #' ',(a5)+	Borrar modificador
	move.b #' ',(a5)

	cmp.b #'3',d0
	bgt.s .res
	sub.b #'0',d0		S¢lo (0..3) para velocidad
	move d0,speed_DMA
	bra.s .loop_cmd

.res	ori.b #('a'-'A'),d0	Pasar a min£sculas
	cmp.b #'r',d0		¨Hacer residente?
	bne.s .loop_cmd		Letra extra¤a
	st ex_residente
	bra.s .loop_cmd
****************	Quitar espacios vacios
.a	movea.l a6,a5
	clr.l d0
	move.b (a5)+,d0		longitud
.c	cmp.b #' ',(a5)+
	bne.s .d		Se acab¢
	addq.l #1,a6
	dbra d0,.c
	moveq #0,d0		No hay l¡nea
.d	move.b d0,(a6)
****************	Pasar a may£sculas
.a_may	movea.l a6,a5
	clr.l d0
	move.b (a5)+,d0
	clr.l d1
.loop_my	move.b (a5),d1
	cmp.b #'\',d1
	bls.s .sigue_loop_my	Si may£sculas o .\?*
	and.b #~('a'-'A'),d1
	move.b d1,(a5)
.sigue_loop_my	addq.l #1,a5
	dbra d0,.loop_my
****************	Fin lmente, interpretar el comando
.fin_loop	tst.b (a6)		¨Hay comando?
	bne.s .comenzar

.copy_como	lea COMODIN(pc),a5	No hay comando, poner comodin
	movea.l a6,a4
	clr.l d0
	move.b (a5)+,d0
	move.b d0,(a4)+		Poner longitud
	subq.b #1,d0
.loop	move.b (a5)+,(a4)+
	dbra d0,.loop

.comenzar	Dgetpath #_path,#0	Camino por defecto
	clr.l d6
	move.b (a6)+,d6		Leer largo
	clr.b 0(a6,d6.w)	Final de cadena
	move.l a6,a5		Buscar *.MOD
	move d6,d0
	clr.l d1
.loop_bus	move.b (a5)+,d1
	cmp.b #'*',d1
	beq.s .fin_loop_bus	Si hay comodin, no hacer nada
	cmp.b #'?',d1
	beq.s .fin_loop_bus
	dbra d0,.loop_bus
	subq.l #1,a5
	cmp.b #'\',-1(a5)	si fin de camino...
	beq.s .resto_comodin
	moveq #3,d0		Buscar '.'
	movea.l a5,a4
.loop_b_pt	cmp.b #'.',-(a4)	Si lo hay, no hacer nada
	beq.s .fin_loop_bus
	dbra d0,.loop_b_pt
	move.b #'\',(a5)+	Ni '.', ni '*' ni '?'
.resto_comodin	lea COMODIN(pc),a4
	clr.l d0
	move.b (a4)+,d0
	subq.b #1,d0
.loop_cp	move.b (a4)+,(a5)+
	dbra d0,.loop_cp
.fin_loop_bus	move.l a6,_camino
	cmp.b #':',1(a6)	Ver si es un camino
	bne.s camin

	lea 0(a6,d6.w),a5	Final
	move.b (a6)+,d6		Nuevo drive
	sub.b #'A',d6
	Dsetdrv d6

	addq #1,a6		apuntador a camino
.loop1	cmp.l a5,a6
	beq.s camin
	cmp.b #'\',(a5)		Buscar el £ltimo '\'
	beq.s encontrado
	subq.l #1,a5
	bra.s .loop1
encontrado	clr.b (a5)		Temporalmente, quitarlo
	Dsetpath a6

	move.b #'\',(a5)	Recuperarlo
camin	move.l a6,_camino
	rts

***********************************************	Inicializar al ordenador
_inicializar:
	Super
****************	Modificacion para el Falcon
*	bclr #7,1+DMAcontr.w

	move #128,-(sp)
	trap #14	locksnd
	addq.l #2,sp

	move #3,-(sp)
	move #4,-(sp)
	move #130,-(sp)
	trap #14	soundcmd: sumador recibe de la matriz y el ADC
	addq.l #6,sp

*	move #3,-(sp)
*	move #5,-(sp)
*	move #130,-(sp)
*	trap #14	soundcmd: Pasar del PSG al ADC
*	addq.l #6,sp
*
*	move #3,-(sp)
*	move #6,-(sp)
*	move #130,-(sp)
*	trap #14	soundcmd: Setprescale a /160
*	addq.l #6,sp

	move #0,-(sp)
	move #132,-(sp)
	trap #14	setmode a 8 bit stereo
	addq.l #4,sp

	move #0,-(sp)
	move #0,-(sp)
	move #133,-(sp)
	trap #14	settracks a 0 replay, 0 record
	addq.l #6,sp

	move #0,-(sp)
	move #134,-(sp)
	trap #14	setmontracks a pista 0
	addq.l #4,sp

	move #1,-(sp)
	move #0,-(sp)
	move #135,-(sp)
	trap #14	setinterrupt a Timer A en Replay
	addq.l #6,sp

	move #2,-(sp)
	move #136,-(sp)
	trap #14	buffoper a Replay repeat
	addq.l #4,sp

	move #1,-(sp)		No protocolo
	move #1,-(sp)		Clock prescale
	move #0,-(sp)		Internal 25.175Mhz
	move #8,-(sp)		Salida solo DAC
	move #0,-(sp)		Entrada solo DMA replay
	move #139,-(sp)
	trap #14	devconnect
	lea 12(sp),sp

****************	Salvar paleta de colores activa
	lea palette.w,a0
	lea ex_paleta(pc),a1
	moveq #15,d0
.pal	move (a0)+,(a1)+
	dbra d0,.pal
*	pea ex_paleta(pc)
*	move #16,-(sp)
*	move #0,-(sp)
*	move #94,-(sp)		Leer paleta
*	trap #14
*	lea 10(sp),sp

	tst ex_residente
	bne.s .rex
	Cursconf #0,#0		Apagar el cursor alfanum‚rico !!!

	tst ex_color
	beq.s .sigue
*	Setscreen #-1,#-1,#0	Poner en baja resoluci¢n !!!
	move #%10110010,-(sp)	Modo compatible, VGA, STBAJA
	move #3,-(sp)
	move.l #-1,-(sp)
	move.l #-1,-(sp)
	move #5,-(sp)
	trap #14
	lea 14(sp),sp
	bsr EX_PON_PALETA	Poner nueva paleta de colores!!!
	Cconws_p ini_texto_color(pc)	Iniciar color de texto !!!
.sigue	bsr EX_PON_PANTALLA	Poner nueva pantalla!!!
****************	Activar Blitter
.rex
*	Blitmode #-1		Activar el Blitter
*	btst #1,d0		Hay blitter?
*	beq.s .no_blitter
*	bset #0,d0		FALCON BLITTER:CAMBIA COLOR (?)
*	Blitmode d0		Activarlo
.no_blitter:
****************	Par metros de dibujo
	Physbase		Hallar direcci¢n f¡sica
	movea.l d0,a2		Base de pantalla
	tst ex_color
	beq.s .alt
	BARRA_color 113,16,POSTRE	Posicionar barras
	BARRA_color 113,64,POSBAS
	BARRA_color 113,112,POSLEF
	BARRA_color 113,144,POSRIG
	BARRA_color 105,208,POSVOL
	BARRA_color 33,144,POSVUML
	BARRA_color 33,160,POSVUMR
	bra .fin
.alt	BARRA_alta 113,16,POSTRE	Posicionar barras
	BARRA_alta 113,64,POSBAS
	BARRA_alta 113,112,POSLEF
	BARRA_alta 113,144,POSRIG
	BARRA_alta 105,208,POSVOL
	BARRA_alta 34,144,POSVUML
	BARRA_alta 34,160,POSVUMR
	lea iniposic+3(pc),a0	Iniciar posiciones de texto
	moveq #TOTALPOSIC,d0
.lopito	moveq #0,d1
	move.b (a0),d1
	sub.b #32,d1
	lsl d1
	add.b #32,d1
	move.b d1,(a0)
	addq.l #5,a0
	dbra d0,.lopito
	lea TEXTO8+3(pc),a0	Ajustar posici¢n letreros
	add.b #10,(a0)
	lea TEXTO10+3(pc),a0
	addq.b #7,(a0)
	lea TEXTO11+2(pc),a0
	subq.b #1,(a0)+
	addq.b #2,(a0)
	lea TEXTO4+3(pc),a0
	addq.b #2,(a0)
	addq.l #5,a0
	addq.b #2,(a0)
	lea AFIRMA+1(pc),a0	Ajusta la inversi¢n
	move.b #'q',(a0)
	lea NIEGA+1(pc),a0
	move.b #'p',(a0)
	Cconws_p NIEGA(pc)	S¢lo negar si alta
	lea ancho(pc),a0	Ancho de pantalla
	move.l #80,(a0)+
	move.l #80-4,(a0)
.fin
	tst ex_residente
	bne.s .rexi
	lea _comando(pc),a0	Pintar l¡nea de comando !!!
	tst ex_color		!!!
	beq.s .alta		!!!
	clr.b 17(a0)		Limitar l¡nea !!!
	bra.s .sigue11		!!!
.alta	clr.b 57(a0)		!!!
.sigue11	Cconws_p TEXTO9(pc)	!!!
	Cconws_p _comando(pc)	Pintar el comando !!!

	move.b conterm.w,ant_conterm	!!!
	andi.b #%1010,conterm.w	Quitar pitidos !!!
.rexi	move #$7FF,DMAmask.w	Microwire
****************	Valores por defecto
	move #FRAMES,n_frames	N£mero de cuadros
	move #LFRAME_2,l_frames	Longitud de los cuadros
	bsr VOLUMENES		Generar tabla de volumenes
	tst ex_residente
	bne.s .rex1
	bsr GEN_VUM		Generar los v£metros !!!
	bsr PINT_TUNE		Pintar tono (por 1¦ vez)!!!
	Ikbdws #0,#nomouse	Parar Rat¢n !!!
	Cconws_p TEXTO8(pc)	!!!
	Cconws_p modo_normal(pc)	Pintar Modo de trabajo Normal !!!
	move.l $70.w,SVBL	Guardar rutina vertical !!!
*	cmp #3,speed_DMA	50Khz? !!!
*	bne.s .si_vbl		!!!
*	cmp #_MCH_TT,ex_machine	TT? !!!
*	beq.s .si_vbl		!!! FALCON si VBL
*	move.l #FINVBL,$70.w	!!!
*	bra.s .sig		!!!
.si_vbl	move.l #VBLHARD,$70.w	Nueva VBL	!!!
.sig	move.l $118.w,STEC	Guardar rutina teclado !!!
	move.l #TECHARD,$118.w	Nueva Tec !!!
	Xbtimer #3,#%111,#246,#TIMERD	Poner timer D a 50 Hz !!!
	Jdisint #TIMED		!!!
.rex1	Xbtimer #0,#%1000,#1,#TIMERA	Poner timer A modo contador
	Jdisint #TIMEA		Desactivar Timer A
	User
	rts

***********************************************	Recuperar estado anterior
_recuperar	Super

	move #0,-(sp)		No hacer nada mas
	move #136,-(sp)		buffoper
	trap #14
	addq.l #4,sp

	move #129,-(sp)
	trap #14	unlocksnd
	addq.l #2,sp

	move.l SVBL(pc),$70.w	Recuperar VBL
	move.b ant_conterm(pc),conterm.w Si pitido
	bsr borrar_buf_tec	Esperar la no pulsaci¢n
	move.l STEC(pc),$118.w	Recuperar teclado
	User
	Jenabint #TIMEC		Reactiver timer
	Mfree CUADRO1(pc)	Liberar cuadros
	Mfree CUADRO2(pc)
	tst ex_color
	beq.s .alta
*	Setscreen #-1,#-1,ex_resolucion(pc) Poner anterior resoluci¢n
	bra.s .sigue
.alta	Cconws_p AFIRMA(pc)
.sigue
*	pea ex_paleta(pc)
*	move #16,-(sp)
*	move #0,-(sp)
*	move #93,-(sp)		Recuperar anterior paleta
*	trap #14
*	lea 10(sp),sp
	lea ex_paleta(pc),a0
	Setpalette a0		Anterior paleta
	Ikbdws #0,#simouse	Sigue Rat¢n
	rts

*********************************************** Programa principal
_main	Super

****************	Modificar par metros
	move #50,conta_timera	2 segundos
	lea l_frames(pc),a0	Asignar tama¤o de buffers
	move speed_DMA,d0
	cmp #0,d0		Si 6Khz
	bne.s .l1
	move #LFRAME_0,(a0)
.l1	cmp #1,d0		Si 12Khz
	bne.s .l2
	move #LFRAME_1,(a0)
.l2	cmp #2,d0		Si 25Khz
	bne.s .l3
	move #LFRAME_2,(a0)
.l3	cmp #3,d0		Si 50Khz
	bne.s .sigue
	move #12,conta_timera	2 segundos
	move #LFRAME_3,(a0)
	bra.s .sigue		FALCON si VUMETROS
	cmp #_MCH_TT,ex_machine	Un TT?
	beq.s .sigue
*****	move #FRAMES_50,n_frames	es un caso especial
.no_vum	lea si_vumetros(pc),a0	No hay v£metros
	move.l #$4E714E71,(a0)+	Nop-Nop...
	move #$4E71,(a0)
	bra.s .sigue01
****************	Preparar la rutina de interrupci¢n
.sigue	tst ex_residente
	bne.s .no_vum

.sigue01	clr.l d7
	move l_frames(pc),d7	LFRAME
	move d7,d6
	lsr d6		LFRAMES/2
	subq #1,d6		Hecho LFRAMES/2-1
	move d6,l_frames_e
	mulu n_frames(pc),d7	FRAMES*LFRAME
	lsl d7		*2
	move.l d7,largo_buffer	Hecho (LFRAME*2)*FRAMES
*	lsr #2,d7		Hecho (LFRAME*2)*FRAMES/4
*	subq #1,d7
	lsr d7		*2 bytes cada instrucci¢n
	lea inversion(pc),a1	Acondicionar la inversi¢n
*.lp2	move #$B19C,(a1)+	"eor.l d0,(a4)+"
*	dbra d7,.lp2
	lea 0(a1,d7.w),a1
	lea si_vumetros(pc),a0	Fin de la inversi¢n
	move #(fin_timer_a-si_vumetros)/2,d0
.lp1	move (a0)+,(a1)+	(llamada a v£metros)
	dbra d0,.lp1
****************	Cuadros de m£sica, frecuencias y DMA
	move.l largo_buffer(pc),d7	Asignar cuadros de sonido
	addq.l #8,d7		por si acaso...
	Malloc d7
	move.l d0,CUADRO1	Cuadros de sonido
	Malloc d7
	move.l d0,CUADRO2
	tst ex_residente
	beq.s .rex
	lsl.l d7		!!!
	move.l d7,largo_programa	!!!
.rex	bsr borrar_buffer	Borrarlos
	bsr GEN_FRQ		Generar tablas de frecuencias
	bsr PONDMA		Inicializar chip DMA
****************	Loop principal
_LOO1	Fsfirst _camino(pc),#0	Buscar el primero
	tst d0
	bne EXIT
_LECTURA	Cconws_p TEXTO10(pc)	Pintar nombre de fichero
	moveq #12,d0		Longitud del nombre
	lea _fichero(pc),a1	Direcci¢n del fichero
	lea NAME(pc),a0		Direcci¢n de la cadena
	bsr COPIAR_STR
	Cconws a1

	tst ex_residente
	beq.s .rex
	move.l largo_programa(pc),d7	!!!
	add.l DTA_size+DT(pc),d7	!!!
	move.l d7,largo_programa	!!!

.rex	Malloc DTA_size+DT(pc)	Pedir memoria para ‚l
	bmi.s _LOOP
	move.l d0,MUZEXX	Leerlo
	clr d7
	bsr LOAD_MOD
	bne.s _LLOOP
	moveq #20,d0		Largo de la canci¢n
	movea.l MUZEXX(pc),a0
	lea NAM(pc),a1
	bsr.s COPIAR_STR
	Cconws_p ini_texto_color(pc)	Iniciar color de texto !!!
	Cconws_p TEXTO1(pc)	Pintar t¡tulo
	bsr INIT_MUZ		Inicializar
	clr FIN
	tst ex_residente
	beq.s .rex3
	clr SIFIN		!!!
.rex3	bsr ON		Tocar
	tst ex_residente
	beq.s .rex1
	bra.s EXIT		!!!

.rex1	bsr.s REINSTAL		Volver
_LLOOP	Mfree MUZEXX(pc)	Liberar memoria
	cmpi.b #$01,d7		Si pulsado Esc, salir
	beq.s EXIT		Si Space, buscar otro
_LOOP	Fsnext		Buscar siguiente
	tst d0		Error?
	beq _LECTURA		No, leerlo y tocar

	bra _LOO1		Repetir, hasta Esc
EXIT	User
	rts

*********************************************** Para copiar strings
COPIAR_STR	Push.l d0/a0-a1,m
	bra.s .ininameloop
.name1	move.b (a0)+,(a1)+
.ininameloop	dbeq d0,.name1
	tst d0		Fin de nombre?
	bmi.s .finname		Si, acabar
	subq.l #1,a1		Rellenar de blancos
.name2	move.b #' ',(a1)+
	dbra d0,.name2
.finname	clr.b (a1)		Poner 0 al final
	Pop.l d0/a0-a1,m
	rts

*********************************************** Reinstalar las interrupciones
REINSTAL	bclr #0,DMAcontr.w	Apagar chip DMA
	Jdisint #TIMEA		Desactivar Timer A

	Jenabint #TIMEC
	bsr.s borrar_buffer

*	cmp #3,speed_DMA	FALCON si BORRA
*	bne.s .borrar_vum	Si <>50Khz, borrar v£metros
*	cmp #_MCH_TT,ex_machine
*	bne.s .fin_rest

.borrar_vum	move.l ancho_4(pc),d3	Offset
	moveq #64-1,d2
	tst ex_color
	bne.s .color
	moveq #128-1,d2
	moveq #-1,d1
.color	movea.l POSVUML(pc),a0	Borrar v£metros
	move d2,d0
.clrr3	tst ex_color
	beq.s .alta
	clr.l (a0)+
	clr.l (a0)
	bra.s .sigue
.alta	move.l d1,(a0)+
.sigue	adda.l d3,a0
	dbra d0,.clrr3

	movea.l POSVUMR(pc),a0	Borrar v£metro derecho
	move d2,d0
.clrr4	tst ex_color
	beq.s .alta2
	clr.l (a0)+
	clr.l (a0)
	bra.s .sigue2
.alta2	move.l d1,(a0)+
.sigue2	adda.l d3,a0
	dbra d0,.clrr4

.fin_rest	tst ex_residente
	bne.s .rex
	WAITESP 2		!!!
.rex	rts

*********************************************** Borrar buffer de sonido
borrar_buffer	move.l largo_buffer(pc),d0
	lsr d0
	move.l d0,d1
	movea.l CUADRO1(pc),a0
.clrr1	clr (a0)+
	dbra d0,.clrr1

	movea.l CUADRO2(pc),a0
.clrr2	clr (a0)+
	dbra d1,.clrr2
	rts

*********************************************** Timer D, para la espera
TIMERD	bclr #4,isrb.w
	addq #1,waitc
	rte

*********************************************** Subrutina de lectura
LOAD_MOD	Fopen NAME(pc),#0	Abrir fichero
	move.l d0,d7		Handle
	tst.l d0
	bmi.s WRONG_		Error en apertura
	Fread d7,#$FFFFF,MUZEXX(pc)	Leer m¢dulo
	tst.l d0
	bmi.s WRONG_		Error en lectura
	Fclose d7		Cerrar fichero
	tst.l d0		Error en cerrar
WRONG_	rts

*********************************************** Inicializar la m£sica
INIT_MUZ	lea SEQ(pc),a0
	lea PAT(pc),a1
	lea NBR_INS(pc),a2
	movea.l MUZEXX(pc),a3
	move #472,(a0)		Offsets a los datos del .MOD
	move #600,(a1)
	move #15,(a2)
	clr FIN		Indicador de formato
	lea tipo_MK(pc),a4
	cmpi.l #'M.K.',1080(a3)
	beq.s .1
	lea tipo_FLT4(pc),a4
	cmpi.l #'FLT4',1080(a3)
	bne.s ._SNDT

.1	st FIN		Es del Noise Tracker!
	move #952,(a0)
	move #1084,(a1)
	move #31,(a2)
	bra.s .hacer
._SNDT	lea tipo_SNDT(pc),a4
.hacer	Cconws_p TEXTO11(pc)
	Cconws a4
****************
	movea.l MUZEXX(pc),a0	Direcciones a los datos
	movea.l a0,a1
	adda SEQ(pc),a0
	adda PAT(pc),a1
	move.l a0,SEQ
	move.l a1,PAT

	move.l #$80,d0		Encontrar tama¤o de las
	clr.l d1		partituras
.muz0	move.l d1,d2
	subq #1,d0
.muz1	move.b (a0)+,d1
	cmp.b d2,d1
	bgt.s .muz0		Encontrar el mayor en SEQ
	dbra d0,.muz1
	addq.b #1,d2		mas 1

	Push.l d2
	Push.l d2
	Cconws_p TEXTO2(pc)	Pintar n£mero de partituras
	Pop.l d2
	move.b d2,d0
	bsr PINTB
	Cconws_p TEXTO3(pc)	Pintar n£mero de posiciones
	movea.l SEQ(pc),a0
	moveq #0,d0
	move.b -2(a0),d0
	move d0,TRK		Contador de pista
	move d0,TOTALTR		N£mero total de pistas
	bsr PINTB
	Pop.l d2

	swap d2		* 64K
	lsr.l #6,d2		/64=Kb ocupan las partituras
	move.l PAT(pc),a6
	adda.l d2,a6		Comienzo de samples

	lea BUFFER,a5		Buffer para invertir
*******
	lea INS(pc),a2		Borrar datos. 4/93
	moveq #31,d0
.lp	clr.l (a2)
	clr.l 4(a2)
	clr.l 8(a2)
	clr 12(a2)
	lea LINS(a2),a2
	dbra d0,.lp
*******
	lea LINS+INS(pc),a2	Borrar datos. 4/93
	movea.l MUZEXX(pc),a1
	lea 20(a1),a1		Comienzo datos samples
	move NBR_INS(pc),d0	Para todos los samples
	subq #1,d0

_muz2	tst 22(a1)		Testear longitud
	beq END_REVE

	move.l a6,4(a2)		Direcci¢n de comienzo
	move.l a6,a4		Para luego invertir

	clr.l d1
	move 22(a1),d1		Tama¤o del sample
	lsl.l #1,d1		*2
	adda.l d1,a6		Siguiente sample
	move.l d1,d4		Para luego invertir
	move.l d1,d5
	swap d1
	move.l d1,(a2)		Invertido, para el trabajo

	move 24(a1),12(a2)	Volumen inicial

	clr.l d1
	move 28(a1),d1		Tama¤o del loop
	lsl.l #1,d1
	cmp.l #2,d1		Valor m¡nimo
	bne.s _MUZ4
	clr.l d1
_MUZ4	move.l d1,d3
	swap d1		Invertido, para el trabajo
	move.l d1,8(a2)

	tst.l d3		Si hay loop, recalcular
	beq.s invertir		el valor inicial del sample

	clr.l d1
	move 26(a1),d1		Valor de repeat
	tst FIN		Tipo de fichero
	beq.s .ajuste
	lsl.l #1,d1		Si Noise, *2

.ajuste	sub.l d3,d5		Tama¤o - loop - Repeat
	sub.l d1,d5
	bpl.s .noerror		Error primer Soundtracker
	add.l d1,d5		Corregir
	lsr.l #1,d1		/2
	sub.l d1,d5

.noerror	add.l d5,4(a2)		Nuevo valor de inicio sample

	add.l d1,d3		Loop + Repeat
	swap d3
	move.l d3,(a2)		Nuevo tama¤o

invertir	tst.l d4		Tama¤o del sample
	beq.s END_REVE		Si no hay, acabar
	subq.l #1,d4
	move.l d4,d2		Para luego
	movea.l a4,a3		Inicio del sample
.rev1	move.b (a3)+,(a5)
	eori.b #$80,(a5)+	Pasar a valor absoluto
	dbra d4,.rev1

	movea.l a4,a3		Inicio del sample
.rev2	move.b -(a5),(a3)+	Recolocar en origen
	dbra d2,.rev2

	tst.l 8(a2)		Si no hay loop ...
	bne.s END_REVE
	move.l 4(a2),a4
	move.b #$80,(a4)	Transici¢n a 0 (?)

END_REVE	lea 30(a1),a1
	lea LINS(a2),a2
	dbra d0,_muz2
	rts

*********************************************** Borrar buffer del teclado
borrar_buf_tec	btst #0,keyctl.w
	beq.s .fin
	move.b keybdport.w,d7
	bra.s borrar_buf_tec
.fin	rts
	
*********************************************** Lectura del teclado
TECHARD	pea (a0)
	move d0,-(sp)
	clr d0
	lea keyctl.w,a0		ACIA
.repe	move.b (a0),d0
	btst #7,d0		¨Interrupci¢n?
	beq.s .knobuff		==>FALTA TRATAR MIDI<==
	btst #0,d0
	beq.s .knobuff
	move.b keybdport-keyctl(a0),d0	Leer teclado
	move d0,buffer_tec
.knobuff 	btst #4,gpip.w		Mas interrupciones?
	beq.s .repe		Si
	bclr #6,isrb.w		Borrar interrupci¢n
	move (sp)+,d0
	movea.l (sp)+,a0
	rte


*********************************************** Poner en marcha
ON	move #6,SPD		Velocidad por defecto
	bsr RESTART	 	Reiniciar
*	move #12,SPEED
	bsr.s borrar_buf_tec

	tst ex_residente
	bne.s .rex
	Jdisint #TIMEC		!!!
.rex	bsr init_PING_PONG
	bsr PING_PONG
	ori #$0700,sr
	move conta_timera(pc),contador_timera
	move.l #TIMERA1,$134.w	Poner Timer A
	andi #$F3FF,sr
	ori #3,DMAcontr.w	Comienzo m£sica
	Jenabint #TIMEA 	Activar Timer A
	stop #$2300
	tst ex_residente
	beq.s PROGRAM
	rts		!!!

PROGRAM	lea buffer_tec(pc),a0
	move (a0),d0
	clr (a0)
	tst d0
	beq.s VERFIN
	cmpi.b #$39,d0		Pulsado Space
	beq.s FINON
	cmpi.b #$01,d0		Pulsado Esc
	bne.s PROGRAM0		Ver resto de teclas
FINON	move d0,d7
	ori #$0700,sr
	move.l #TIMERAB,$134.w	Parar la m£sica
	andi #$F3FF,sr
	rts		Salir

VERFIN	tst SIFIN		Seg£n tipo de reproducci¢n
	beq PINT_TR
	tst FIN
	beq PINT_TR
	rts

PROGRAM0	cmpi.b #$32,d0		Pulsado Modo de reproducci¢n
	bne.s PROGRAMI
	Cconws_p TEXTO8(pc)
	lea modo_normal(pc),a0
	clr FIN
	not SIFIN		Cambiar de modo
	bne.s .pinta
	lea modo_loop(pc),a0
.pinta	Cconws a0
	bra.s PROGRAM

PROGRAMI	lea SETSAM_DAT(pc),a0
	movea.l POSVOL(pc),a5	Barra volumen general
	moveq #40,d7		Tama¤o
	tst ex_color
	beq.s .alta
	moveq #2,d5		Factor
	bra.s .sigue
.alta	moveq #4,d5
.sigue	cmpi.b #$4A,d0		Bajar el volumen general
	bne.s PROGRAM1
	move #PERI|VOLUMG|0,d0
	bra BAJAR

PROGRAM1	cmpi.b #$4E,d0		Subir el volumen general
	bne.s PROGRAM2
	move #PERI|VOLUMG|40,d0
	bra SUBIR

PROGRAM2	addq.l #2,a0
	movea.l POSLEF(pc),a5	Barra volumen izquierdo
	moveq #20,d7		Tama¤o
	tst ex_color
	beq.s .alta
	moveq #3,d5		Factor
	bra.s .sigue
.alta	moveq #6,d5
.sigue	cmpi.b #$4B,d0		Bajar volumen izquierdo
	bne.s PROGRAM3
	move #PERI|VOLUML|0,d0
	bra BAJAR

PROGRAM3	cmpi.b #$52,d0		Subir volumen izquierdo
	bne.s PROGRAM4
	move #PERI|VOLUML|20,d0
	bra SUBIR

PROGRAM4	addq.l #2,a0
	movea.l POSRIG(pc),a5	Barra volumen derecho
	cmpi.b #$4D,d0		Bajar volumen derecho
	bne.s PROGRAM5
	move #PERI|VOLUMR|0,d0
	bra BAJAR

PROGRAM5	cmpi.b #$47,d0		Subir volumen derecho
	bne.s PROGRAM6
	move #PERI|VOLUMR|20,d0
	bra SUBIR

PROGRAM6	addq.l #2,a0
	movea.l POSTRE(pc),a5	Barra agudos
	moveq #12,d7		Tama¤o
	tst ex_color
	beq.s .alta
	moveq #5,d5		Factor
	bra.s .sigue
.alta	moveq #10,d5
.sigue	cmpi.b #$65,d0		Bajar agudos
	bne.s PROGRAM7
	move #PERI|TREBLE|0,d0
	bra BAJAR

PROGRAM7	cmpi.b #$66,d0		Subir agudos
	bne.s PROGRAM8
	move #PERI|TREBLE|12,d0
	bra SUBIR

PROGRAM8	addq.l #2,a0
	movea.l POSBAS(pc),a5	Barra bajos
	cmpi.b #$63,d0		Bajar graves
	bne.s PROGRAM9
	move #PERI|BASS|0,d0
	bra BAJAR

PROGRAM9	cmpi.b #$64,d0		Subir graves
	bne.s PROGRAM10
	move #PERI|BASS|12,d0
	bra SUBIR

PROGRAM10	cmpi.b #$1C,d0		Iniciar de nuevo la canci¢n
	bne.s PROGRAM11
	bsr REINSTAL
	clr FIN
	bra ON

PROGRAM11	cmpi.b #$50,d0		Ir hacia adelante
	bne.s PROGRAM12
	tst TRK
	beq PROGRAM
	move #1,POS		Reiniciar partitura ya
	bra PROGRAM

PROGRAM12	cmpi.b #$48,d0		Ir hacia atr s
	bne.s PROGRAM13
	move TOTALTR(pc),d0
	cmp TRK(pc),d0
	beq PROGRAM
	subq.l #1,MUS
	addq #1,TRK
	bra PROGRAM

PROGRAM13	cmpi.b #$0C,d0		Reducir tono
	bne.s PROGRAM14
	tst tune
	beq PROGRAM
	subq #1,tune
	bsr GEN_FRQ
	bsr.s PINT_TUNE
	bra PROGRAM

PROGRAM14	cmpi.b #$0D,d0		Aumentar tono
	bne PROGRAM
	move #$FF,d0
	cmp tune(pc),D0
	beq PROGRAM
	addq #1,tune
	bsr GEN_FRQ
	bsr.s PINT_TUNE
	bra PROGRAM

*********************************************** Parte dedicada a pintar datos
******* Pintar valor de tune
PINT_TUNE	Cconws_p TEXTO7(pc)
	move tune(pc),d0
	bsr PINTB
	rts

******* Pintar valor de la pista actual
PINT_TR	move TRK(pc),d7		Pista actual
	cmp PISTA(pc),d7
	beq.s PINT_PT 		Iguales, acabar
	move d7,PISTA
	Cconws_p TEXTO4(pc)
	move TOTALTR(pc),d0	Nuevo valor de pista
	sub.b d7,d0
	bsr PINTB		Pintar pista
	bra PROGRAM

******* Pintar partitura actual
PINT_PT	movea.l MUS(pc),a0
	moveq #0,d7
	move.b (a0),d7 		Partitura actual
	cmp PART(pc),D7
	beq.s PINT_SP		Iguales, acabar
	move d7,PART
	Cconws_p TEXTO5(pc)
	move.b d7,d0
	bsr PINTB		Pintar partitura
	bra PROGRAM

******* Pintar velocidad
PINT_SP	move SPD(pc),d7
	cmp VELOCI(pc),d7	Velocidad actual
	beq PROGRAM
	move d7,VELOCI
	Cconws_p TEXTO6(pc)
	move.b d7,d0
	bsr PINTB
	bra PROGRAM


*********************************************** Cambiar los parametros del DMA
BAJAR	cmp (a0),d0
	beq PROGRAM
	subq #1,(a0)		Subir un nivel
	bra.s PON

SUBIR	cmp (a0),d0
	beq PROGRAM
	addq #1,(a0)		Bajar un nivel

*********************************************** Escribir al DMA
PON	move (a0),d6 		Tama¤o barra a pintar
	move d6,d0
	bsr MWWRITE	 	Actualiza DMA
	bsr.s PINBARR		Pintar la barra
	bra PROGRAM		Volver al bucle

*********************************************** Pintar barra normal
* A5: Posici¢n en pantalla	*
* D7: Tama¤o total de la barra	*
* D6: Tama¤o barra a pintar	*
* D5: Factor de multiplicaci¢n	*
* D4: Constante -1	*
* D2 y D3 offset	*
*********************************
PINBARR	moveq #-1,D4		Entreniveles
	move.l ancho(pc),d2	offset
	move.l ancho_4(pc),d3
	andi #63,d6
	sub d6,d7		Parte negra
	mulu d5,d7		Factor de escala
	bra.s INILOOP
BLOOP	tst ex_color
	beq.s .alta
	clr.l (a5)+		Parte superior negra
	clr.l (a5)
	bra.s .sigue
.alta	move.l d4,(a5)+
.sigue	adda.l d3,a5
INILOOP	dbra d7,BLOOP

	tst d6		Si hay niveles ...
	beq.s FINBAR
	subq #1,d5
	tst ex_color
	beq.s INILOP1
	move.l #CLOR,d1
	bra.s INILOP1

BLOOP1	move d5,d0		Factor de escala
	tst ex_color
	beq.s .alta
	clr.l (a5)+		Pintar primera raya
	clr.l (a5)
	adda.l d3,a5
	bra.s INILOP2
.alta	move.l d4,(a5)
	adda.l d2,a5
	move.l d4,(a5)
	adda.l d2,a5
	subq #1,d0
	bra.s INILOP2
BLOOP2	tst ex_color
	beq.s .alta
	move.l d1,(a5)+
	move.l d1,(a5)
	adda.l d3,a5
	bra.s INILOP2
.alta	move.l #$EAAAAAAB,d1	Dibujo de barras
	btst #0,d0
	bne.s .inilop
	move.l #$C0000003,d1
.inilop	move.l d1,(a5)		Pintar
	adda.l d2,a5
INILOP2	dbra d0,BLOOP2
INILOP1	dbra d6,BLOOP1
FINBAR	rts

*********************************************** Inicializar al DMA y Microwire
PONDMA	move speed_DMA,d7
	or d7,DMAmode.w		Hz. DMA
	lea SETSAM_DAT(pc),a0	Iniciar al LMC1992

	bsr MWWRITE1
	movea.l POSVOL(pc),a5	Barra volumen general
	moveq #40,d7		Tama¤o
	tst ex_color
	beq.s .alta_gen
	moveq #2,d5		Factor
	bra.s .sigue_gen
.alta_gen	moveq #4,d5
.sigue_gen	bsr PINBARR

	bsr.s MWWRITE1
	movea.l POSLEF(pc),a5	Barra volumen izquierdo
	moveq #20,d7		Tama¤o
	tst ex_color
	beq.s .alta_izq
	moveq #3,d5		Factor
	bra.s .sigue_izq
.alta_izq	moveq #6,d5
.sigue_izq	bsr PINBARR

	bsr.s MWWRITE1
	movea.l POSRIG(pc),a5	Barra volumen derecho
	moveq #20,d7		Tama¤o
	tst ex_color
	beq.s .alta_der
	moveq #3,d5		Factor
	bra.s .sigue_der
.alta_der	moveq #6,d5
.sigue_der	bsr PINBARR

	bsr.s MWWRITE1
	movea.l POSTRE(pc),a5	Barra agudos
	moveq #12,d7		Tama¤o
	tst ex_color
	beq.s .alta_treble
	moveq #5,d5		Factor
	bra.s .sigue_treble
.alta_treble	moveq #10,d5
.sigue_treble	bsr PINBARR

	bsr.s MWWRITE1
	movea.l POSBAS(pc),a5	Barra bajos
	moveq #12,d7		Tama¤o
	tst ex_color
	beq.s .alta_bass
	moveq #5,d5		Factor
	bra.s .sigue_bass
.alta_bass	moveq #10,d5
.sigue_bass	bsr PINBARR

	bsr.s MWWRITE1
	rts

	dc.b "*DMA"
SETSAM_DAT	dc.w PERI|VOLUMG|35	Volumen general
	dc.w PERI|VOLUML|18	Volumen izquierdo
	dc.w PERI|VOLUMR|18	Volumen derecho
	dc.w PERI|TREBLE|11	Agudos
	dc.w PERI|BASS|11	Bajos
	dc.w PERI|MIX|1		Mezclador DMA-Yamaha

*********************************************** Escribir en los registros DMA
MWWRITE1	move (a0)+,d0
	move d0,d6
	bsr.s MWWRITE
	moveq #-1,d3
.loop	cmp #$FF7,DMAmask.w
	dbeq d3,.loop
	rts

MWWRITE	cmp #$7FF,DMAmask.w
	bne.s MWWRITE
	move d0,DMAdata.w
	rts

*********************************************** Efecto Ping-Pong
init_PING_PONG	lea _cuadros(pc),a0
	move.l CUADRO1(pc),(a0)+
	move.l CUADRO2(pc),(a0)
	rts
PING_PONG	lea _cuadros(pc),a1
	movem.l (a1),d0-d1
	exg d0,d1
	movem.l d0-d1,(a1)
	move.l d0,d1
	add.l largo_buffer(pc),d1
	lea DMAbasehi.w,a1	Direcci¢n inicial
	movep d0,3(a1)
	swap d0
	move.b d0,1(a1)
	lea DMAendhi.w,a1	Direcci¢n final
	movep.l d1,-1(a1)
	rts

* movep.l d1,-1(a0)
* FALLO!!!: -1(DMAbasehi.w) es justamente DMAcontrol.w !!!!!

*********************************************** Pintar un byte
PINTB	Push.l d0-d1/a0,m
	move.b d0,d1
	lea TAB_HEX(pc),a0
	lsr.b #4,d0		Nibble alto
	andi #$F,d0
	move.b 0(a0,d0),d0
	Push.l d1/a0,m
	Bconout #5,d0		Pintar
	Pop.l d0/a0,m
	andi #$F,d0		Nibble bajo
	move.b 0(a0,d0),d0
	Bconout #5,d0		Pintar
	Pop.l d0-d1/a0,m
	rts

*********************************************** Interrupci¢n vertical
VBLHARD	subq #1,VBCONT
	bne.s FINVBL
	move #VBLS,VBCONT
	subq #1,VBREC
	bne.s FINVBL
	move #VBRE,VBREC
	move highv_altov(pc),VUMLREC	Apagar records
	move highv_altov(pc),VUMRREC
FINVBL	rte

*********************************************** Actualizar v£metros
TIMERB	lea DMAconthi.w,a5
	movep.l -1(a5),d3	Direcci¢n actual del chip
	andi.l #$00FFFFFF,d3	Aqui estuvo el error del TT
	movea.l d3,a5
	move (a5),d3	 	Sample actual
	clr.l d4
	move.b d3,d4		Sample derecha
	beq.s VUM111		Caso 0
	bpl.s VUM1		Si es positivo, nada
	neg.b d4		Poner a positivo
VUM1	subq.b #1,d4
	lsr.b #FACTVU,d4	/FACTOR. Acotar rango
	addq.b #1,d4		Valores m s uno
VUM111:
	move VUMR(pc),d6	Movimiento lento hacia abajo
	beq.s VUM11
	subq.b #CAIDA,d6
	cmp.b d4,d6		Ver el mayor
	bge.s VUM12
VUM11	exg d4,d6
VUM12	move d6,VUMR	 	Nuevo valor del v£metro
	move highv_altov(pc),d4	Poner valor inverso
	sub.b d6,d4
	cmp VUMRREC(pc),d4
	bge.s VUM13
	move d4,VUMRREC		Nuevo record
	move #VBRE,VBREC

VUM13	lsr #8,d3		Sample izquierdo
	clr.l d4
	move.b d3,d4
	beq.s VUM222
	bpl.s VUM2		Si es positivo, nada
	neg.b d4
VUM2	subq.b #1,d4
	lsr.b #FACTVU,d4
	addq.b #1,d4
VUM222:
	move VUML(pc),d6
	beq.s VUM21
	subq.b #CAIDA,d6
	cmp.b d4,d6
	bge.s VUM22
VUM21	exg d4,d6
VUM22	move d6,VUML
	move highv_altov(pc),d4
	sub.b d6,d4
	cmp VUMLREC(pc),d4
	bge.s VUM23
	move d4,VUMLREC
	move #VBRE,VBREC
VUM23:
	tst ex_color
	beq.s VUMETROS_alta
*	bra.s VUMETROS_color

*********************************************** Pintar los v£metros
GRIS	equ	$D555D555
GRIS2	equ	$AAABAAAB
CLOR	equ	$7FFE0000
LLENO	equ	$80018001
LLENO2	equ	-1

VUMETROS_color	movea.l POSVUMR(pc),a5	Barra derecha
	move VUMR(pc),d6	Valor anterior
	bsr PINVUM_color	Pintar
	movea.l POSVUMR(pc),a5	Barra derecha
	move VUMRREC(pc),d4	Record
	bsr.s EX_RECORD_CL

	movea.l POSVUML(pc),a5	Barra izquierdo
	move VUML(pc),d6
	bsr PINVUM_color	Pintar
	movea.l POSVUML(pc),a5	Barra izquierdo
	move VUMLREC(pc),d4
	bra.s EX_RECORD_CL
****************
VUMETROS_alta	movea.l POSVUMR(pc),a5	Barra derecha
	move VUMR(pc),d6	Valor anterior
	bsr PINVUM_bn
	movea.l POSVUMR(pc),a5	Barra derecha
	move VUMRREC(pc),d4	Record
	bsr.s EX_RECORD_BN

	movea.l POSVUML(pc),a5	Barra izquierdo
	move VUML(pc),d6
	bsr PINVUM_bn
	movea.l POSVUML(pc),a5	Barra izquierdo
	move VUMLREC(pc),d4
	bra.s EX_RECORD_BN	Record

***********************************************	Pintar record
* D4: altura del record
* A5: Posici¢n de la barra

****************	En color
EX_RECORD_CL	cmp highv_altov(pc),d4	Si esta fuera, nada
	beq.s fin_color
	move d4,d1
	mulu #320,d4
	lea 0(a5,d4),a5		Direcci¢n record
	move.l #CLOR,d2		Tramas
	move.l d2,d3
	cmp #11,d1 (HIGHV/ALTOV/3)	En rojo o azul
	bgt.s .vum2
	clr.l d2
.vum2	move.l d2,(a5)+		Pintar record (una l¡nea)
	move.l d3,(a5)
fin_color	rts
****************	En mono
EX_RECORD_BN	cmp highv_altov(pc),d4
	beq.s fin_bn
	move d4,d1
	mulu #320,d4
	lea 0(a5,d4),a5		Direcci¢n record
	move.l #LLENO,d2
	moveq #LLENO2,d3
	cmp #11,d1 (HIGHV/ALTOV/3)
	bgt.s .vum2
	move.l #GRIS,d2
	move.l #GRIS2,d3
.vum2	moveq #2,d5		3 l¡neas
.vum22	move.l d2,(a5)
	exg d2,d3
	lea 80(a5),a5
	dbra d5,.vum22
fin_bn	rts


***********************************************	Nuevo modo de pintar v£metros
* A5: Posici¢n en pantalla	*
* D6: Tama¤o barra a pintar	*
* Modifica D7 y A5	*
* Usa D0 y A0		*
*********************************
PINVUM_color	moveq #64-1,d7		Alto de los v£metros
	move d6,d0
	mulu #512,d0		Offset
	lea NEO_VUM,a0		Base
	adda.l d0,a0
	move.l #160-4,d5	Offset en pantalla
.pin_baja	move.l (a0)+,(a5)+
	move.l (a0)+,(a5)
	adda.l d5,a5
	dbf d7,.pin_baja
	rts

PINVUM_bn	moveq #128-1,d7		Alto de los v£metros
	move d6,d0
	mulu #512,d0		Offset
	lea NEO_VUM,a0		Base
	adda.l d0,a0
	moveq.l #80-4,d5	Offset en pantalla
.pin_alta	move.l (a0)+,(a5)+
	adda.l d5,a5
	dbf d7,.pin_alta
	rts


*********************************************** Timer A, esperar un cuadro
TIMERA1	bclr #5,isra.w
	subq #1,contador_timera
	bne.s .fin
	move.l #TIMERA,$134.w	Verdadera rutina
.fin	rte

contador_timera	dc.w 0
conta_timera	dc.w 0

*********************************************** Pseudo Timer A, parar al DMA
TIMERAB	bclr #0,DMAcontr.w	Apagar DMA
	Push.l d0-d1/a0,m
	bsr borrar_buffer
	Pop.l d0-d1/a0,m
	bclr #5,isra.w
	rte

*********************************************** Reinicializar m£sica
RESTART	move SPD(pc),SPEED	Nueva velocidad
	move #1,POS		Nueva posici¢n
	move.l SEQ(pc),MUS	Partituras
	subq.l #1,MUS
	move TOTALTR(pc),TRK

	movea.l VOL_TAB(pc),a0	Apunta a tabla 0 de volumen
	adda.l #128,a0		EL RUIDO ACALLADO!!
	lea V0(pc),a1		Borrar las 4 voces
	moveq #3,d0
.loop	clr.l (a1)+		V0
	clr.l (a1)+		L0
	clr.l (a1)+		F0
	move.l a0,(a1)+		VOL0
	dbra d0,.loop

	movea.l a0,a1		Borrar regsitros
	movea.l a0,a2
	movea.l a0,a3
	clr.l d0
	clr.l d1
	clr.l d2
	clr.l d3
	movem.l d0-d3/a0-a3,REGIS
	rts

*********************************************** Timer A. Componer la m£sica
TIMERA	Push.l d0-d7/a0-a6,m
	lea _cuadros(pc),a0
	movem.l (a0),d0-d1	Intercambiar para la pr¢xima
	exg d0,d1
	movem.l d0-d1,(a0)
	move.l d0,a4
	move.l d0,d1
	add.l largo_buffer(pc),d1
	lea DMAbasehi.w,a1	Direcci¢n inicial
	movep d0,3(a1)
	swap d0
	move.b d0,1(a1)
	lea DMAendhi.w,a1	Direcci¢n final
	movep.l d1,-1(a1)

	bclr #5,isra.w

	Push.l a4		Para luego invertir
	Push.l a4		Para el trabajo
	move n_frames(pc),CNT
*********************************************** Rutina emuladora de Amiga
AMIGA	movem.l REGIS(pc),d0-d3/a0-a3	Estado actual
	move.l (sp),a4
	move.l a4,d5		Para luego invertir
	lea V0(pc),a5		Apuntador al area de datos
	clr.l d7
	movea.l d7,a6		Base primera de volumen

******* PARTE DERECHA.1
AM1	movem.l d0/d3/a0/a3,AREA	Guardar para parte izquierda
	move l_frames_e(pc),d6
	move.l VOL1(pc),d0	Base de volumen 1
	move.l VOL2(pc),d3	Base de volumen 2
	movea.l V1-V0(a5),a0
	movea.l V2-V0(a5),a3
* Loop
AM2L	sub.l a0,d1
	bcc.s V21
	move.l L1-V0(a5),d1
	movea.l F1-V0(a5),a0
	move.l a0,V1-V0(a5)

V21	sub.l a3,d2
	bcc.s OUT2
	move.l L2-V0(a5),d2
	movea.l F2-V0(a5),a3
	move.l a3,V2-V0(a5)

OUT2	move.l d1,d4
	clr d4
	swap d4
	move.b 0(a1,d4.L),d0
	movea.l d0,a6
	move.b (a6),d7
*	move.b 0(a6,d0.L),d7	Canal 1

	move.l d2,d4
	clr d4
	swap d4
	move.b 0(a2,d4.L),d3
	movea.l d3,a6
	add.b (a6),d7
*	add.b 0(a6,d3.L),d7	Canal 2

_STE_1	roxr.b #1,d7		Media aritm‚tica
	move d7,(a4)+		Canal derecho

******* PARTE DERECHA.2
	sub.l a0,d1
	bcc.s V212
	move.l L1-V0(a5),d1
	movea.l F1-V0(a5),a0
	move.l a0,V1-V0(a5)

V212	sub.l a3,d2
	bcc.s OUT22
	move.l L2-V0(a5),d2
	movea.l F2-V0(a5),a3
	move.l a3,V2-V0(a5)

OUT22	move.l d1,d4
	clr d4
	swap d4
	move.b 0(a1,d4.L),d0
	movea.l d0,a6
	move.b (a6),d7
*	move.b 0(a6,d0.L),d7	Canal 1

	move.l d2,d4
	clr d4
	swap d4
	move.b 0(a2,d4.L),d3
	movea.l d3,a6
	add.b (a6),d7
*	add.b 0(a6,d3.L),d7	Canal 2

_STE_2	roxr.b #1,d7		Media
	move d7,(a4)+		Canal derecho

*******
	dbra d6,AM2L

	movem.l AREA(pc),d0/d3/a0/a3

******* PARTE IZQUIERDA.1
	movem.l d1-d2/a1-a2,AREA	Guardar para recuperar
	movea.l d5,a4
	move l_frames_e(pc),d6

	move.l VOL0(pc),d1	Base de volumen 0
	move.l VOL3(pc),d2	Base de volumen 3

	movea.l (a5),a1		V0-V0
	movea.l V3-V0(a5),a2
* Loop
AM1L	sub.l a1,d0
	bcc.s V31
	move.l L0-V0(a5),d0
	movea.l F0-V0(a5),a1
	move.l a1,(a5)		V0-V0

V31	sub.l a2,d3
	bcc.s OUT
	move.l L3-V0(a5),d3
	movea.l F3-V0(a5),a2
	move.l a2,V3-V0(a5)

OUT	move.l d3,d4
	clr d4
	swap d4
	move.b 0(a3,d4.L),d2
	movea.l d2,a6
	move.b (a6),d7
*	move.b 0(a6,d2.L),d7	Canal 3

	move.l d0,d4
	clr d4
	swap d4
	move.b 0(a0,d4.L),d1
	movea.l d1,a6
	add.b (a6),d7
*	add.b 0(a6,d1.L),d7	Canal 0

_STE_3	roxr.b #1,d7		Sumar y hallar media
	move.b d7,(a4)		Canal izquierdo
	addq.l #2,a4

******* PARTE IZQUIERDA.2
	sub.l a1,d0
	bcc.s V312
	move.l L0-V0(a5),d0
	movea.l F0-V0(a5),a1
	move.l a1,(a5)		V0-V0

V312	sub.l a2,d3
	bcc.s OUT1
	move.l L3-V0(a5),d3
	movea.l F3-V0(a5),a2
	move.l a2,V3-V0(a5)

OUT1	move.l d3,d4
	clr d4
	swap d4
	move.b 0(a3,d4.L),d2
	movea.l d2,a6
	move.b (a6),d7
*	move.b 0(a6,d2.L),d7	Canal 3

	move.l d0,d4
	clr d4
	swap d4
	move.b 0(a0,d4.L),d1
	movea.l d1,a6
	add.b (a6),d7
*	add.b 0(a6,d1.L),d7	Canal 0

_STE_4	roxr.b #1,d7
	move.b d7,(a4)		Canal izquierdo
	addq.l #2,a4

	dbra d6,AM1L

	movem.l AREA(pc),d1-d2/a1-a2
******* FINAL
	movem.l d0-d3/a0-a3,REGIS
	move.l a4,(sp)		Para la pr¢xima

*	bra.s TA_LP		regresar a rutina Timer A
*********************************************** Fin del Timer A
TA_LP	subq #1,SPEED
	bne LOOP_TA

*********************************************** Rutina para leer la m£sica
PLAY	move SPD(pc),SPEED
	moveq #0,d0
	lea MUS(pc),a1
	subq #1,POS		Una posici¢n mas
	bne.s NO_NEW_P
	move #64,POS		Nueva partitura
	addq.l #1,(a1)
	subq #1,TRK
	bpl.s PL1		Se acab¢ la canci¢n?

	st FIN		S¡
	bsr RESTART		reiniciar, por si acaso
	moveq #0,d0
	lea MUS(pc),a1
	movea.l (a1),a0
	movea.l SEQ(pc),a2
	move.b -1(a2),d0	Valor de repetici¢n
	cmp TOTALTR(pc),d0	Ver si mayor que total pistas
	bls.s .pon		no, un valor normal
	clr.l d0		Poner a pista 00, por defecto

.pon	sub d0,TRK		Actualizar contador
	adda.l d0,a0
	move.l a0,(a1)		Posici¢n de la partitura
	tst SIFIN		Acabar la m£sica?
	beq.s PLAY		no, repetir

	ori #$0700,sr
	move.l #TIMERAB,$134.w	Parar la m£sica
	andi #$F3FF,sr
	bra LOOP_TA

PL1	clr.l d0
	movea.l (a1),a0
	move.b (a0),d0		Partitura
	swap d0
	lsr.l #6,d0
	movea.l PAT(pc),a0
	adda.l d0,a0
	move.l a0,ADD_IN_P	Puntero sobre la partitura
NO_NEW_P	movea.l ADD_IN_P(pc),a0
	lea FRQ,a1
	lea INS(pc),a2
	lea COMMAND(pc),a3

	lea VOICE0(pc),a4
	lea VOL0(pc),a6
	bsr LOAD_VOI		Cargar Voz 0

	lea VOICE1(pc),a4
	lea VOL1(pc),a6
	bsr LOAD_VOI		Cargar Voz 1

	lea VOICE2(pc),a4
	lea VOL2(pc),a6
	bsr LOAD_VOI		Cargar Voz 2

	lea VOICE3(pc),a4
	lea VOL3(pc),a6
	bsr LOAD_VOI		Cargar Voz 3

	move.l a0,ADD_IN_P
	movem.l REGIS(pc),d0-d3/a0-a3

	lea VOICE0(pc),a5
	tst.b 20(a5)
	beq.s CONT0
	move.l (a5),d0		Tama¤o del sample
	movea.l 4(a5),a0	Inicio del sample
	move.l 8(a5),L0		Valor de loop
	move.l 12(a5),V0	Frecuencia para sample
	move.l 16(a5),F0	Frecuencia para loop
	sf 20(a5)
CONT0	lea VOICE1(pc),a5
	tst.b 20(a5)
	beq.s CONT1
	move.l (a5),d1
	movea.l 4(a5),a1
	move.l 8(a5),L1
	move.l 12(a5),V1
	move.l 16(a5),F1
	sf 20(a5)
CONT1	lea VOICE2(pc),a5
	tst.b 20(a5)
	beq.s CONT2
	move.l (a5),d2
	movea.l 4(a5),a2
	move.l 8(a5),L2
	move.l 12(a5),V2
	move.l 16(a5),F2
	sf 20(a5)
CONT2	lea VOICE3(pc),a5
	tst.b 20(a5)
	beq.s CONT3
	move.l (a5),d3
	movea.l 4(a5),a3
	move.l 8(a5),L3
	move.l 12(a5),V3
	move.l 16(a5),F3
	sf 20(a5)
CONT3	movem.l d0-d3/a0-a3,REGIS

LOOP_TA:
*********************************************** Tocar efectos
EFFECT	lea FRQ,a1
	lea VOL0(pc),a6
	lea VOICE0(pc),a4
	tst.b 30(a4)		No hay efecto
	beq.s CONT_EFF0
	bsr DO_EFFEC		Realizarlo
	move.l 26(a4),V0	Nueva frecuencia
	tst.l F0		Ver si Loop
	beq.s CONT_EFF0
	move.l 26(a4),F0	Frecuencia de Loop
CONT_EFF0	lea VOL1(pc),a6
	lea VOICE1(pc),a4
	tst.b 30(a4)
	beq.s CONT_EFF1
	bsr DO_EFFEC
	move.l 26(a4),V1
	tst.l F1
	beq.s CONT_EFF1
	move.l 26(a4),F1
CONT_EFF1	lea VOL2(pc),a6
	lea VOICE2(pc),a4
	tst.b 30(a4)
	beq.s CONT_EFF2
	bsr DO_EFFEC
	move.l 26(a4),V2
	tst.l F2
	beq.s CONT_EFF2
	move.l 26(a4),F2
CONT_EFF2	lea VOL3(pc),a6
	lea VOICE3(pc),a4
	tst.b 30(a4)
	beq.s CONT_EFF3
	bsr DO_EFFEC
	move.l 26(a4),V3
	tst.l F3
	beq.s CONT_EFF3
	move.l 26(a4),F3
CONT_EFF3:
***********************************************	Fin Timer A
	subq #1,CNT
	bne AMIGA
*******
	Pop.l a4		Poner signo
	Pop.l a4
	move.l #$80808080,d0
inversion:
	REPT (FRAMES*LFRAME_3*2/4)
	eor.l d0,(a4)+
	ENDR

***********************************************
si_vumetros	jsr TIMERB		Actualizar v£metros !!!
	Pop.l d0-d7/a0-a6,m
fin_timer_a	rte

*********************************************** Cargar datos para una voz
LOAD_VOI	clr.l d0
	clr.l d2
	sf 30(a4)		No hay efecto
	move.b (a0),d2
	move.b 2(a0),d0		Leer instrumento
	lsr.b #4,d0
	andi.b #$F0,d2
	or.b d2,d0		N£mero de instrumento
*	cmp.b #$1F,d0		M ximo instrumento
*	bhi.s LOAD1
	tst.b d0
	bne.s LOAD2		Si hay instrumento
	tst (a0)
	beq FINLOAD 		No hay nota, acabar

LOAD1	move 40(a4),d0		instrumento anterior
LOAD2	move d0,40(a4)		Guardar instrumento
	mulu #LINS,d0

	clr.l d2
	move 12(a2,d0),d2	Volumen
	move.b d2,39(a4)	Volumen en Voice
	lsl.l #8,d2		*256
	add.l VOL_TAB(pc),d2	Mas base de volumen
	move.l d2,(a6)		Guardar en VOLx

	move (a0),d1		Nota a tocar
	andi #$FFF,d1
	beq.s FINLOAD		No nota, salir (1-5-92)

	move.l 0(a2,d0),(a4)	Tama¤o del sample
	move.l 4(a2,d0),4(a4)	Direcci¢n sample
	move.l 8(a2,d0),8(a4)	Tama¤o para Loop

NOLOOP	move.b 2(a0),D0		comando
	andi #$F,d0		Note portamento
	cmp #3,d0
	bne.s PONNOTA		No

	move d1,34(a4)		Note portamento destino
	move 24(a4),d0		Nota actual
	clr.b 38(a4)		Direcci¢n de note
	cmp d0,d1		Comprobar l¡mite
	beq.s NON		Iguales, fin
	bge.s FINLOAD		Mayor, acabar
	move.b #1,38(a4)	La otra direcci¢n
	bra.s FINLOAD
NON	clr 34(a4)		No hay note portamento
	bra.s FINLOAD

PONNOTA	move d1,24(a4)		Nota a tocar
	clr.b 32(a4)		Borrar offset vibrato
	st 20(a4)		Hay nuevo sonido
	lsl #2,d1
	move.l 0(a1,d1),12(a4)	Frecuencia
	move.l 12(a4),16(a4)	Idem, para Loop
	tst.l 8(a4)		Ver si hay Loop
	bne.s FINLOAD
	clr.l 16(a4)		si no hay Loop, no frecuencia

FINLOAD	move 2(a0),d0		Comando
	addq.l #4,a0
	move.b d0,d1
	andi #$F00,d0
	andi #$FF,d1
	lsr #6,d0
	movea.l 0(a3,d0),a5
	jmp (a5)		Salto a comandos

*********************************************** Efectos de sonido
NO_COMMA	rts		No comando
*******			Arpeggio
ARPEGGIO	tst.b d1
	beq.s NO_ARPEG
	move.b #1,21(a4)
	sf 22(a4)
	move.b d1,23(a4)	Poner arpeggio
	st 30(a4)
NO_ARPEG	rts
*******			Portamentos
PORTAMEN0	move.b #1,22(a4)
	move.b d1,23(a4)	Poner Portamento
	st 30(a4)
	rts
PORTAMEN1	move.b #2,22(a4)
	move.b d1,23(a4)	Poner Portamento
	st 30(a4)
	rts
*******			Tone Portamento
TONE	move.b #3,22(a4)
	move.b d1,33(a4)	Poner Tone Portamento
	st 30(a4)
	rts
*******			Vibrato
VIBRATO	move.b #4,22(a4)	Hay vibrato
	move.b d1,37(a4)	Poner info del vibrato
	clr.b 32(a4)		Borrar offset vibrato
	st 30(a4)
	rts
*******			Tr‚molo
TREMOLO	move.b #7,22(a4)	Hay tr‚molo
	move.b d1,37(a4)	Poner comando de tr‚molo
	clr.b 32(a4)		Borrar offset tr‚molo
	st 30(a4)
	rts
*******			Slide Volumen
SLIDE_VOL	tst.b d1
	bne.s nu
sigue_slide	move.b 31(a4),d1	Anterior valor
nu	move.b d1,31(a4)	Guardar
	move.b #$A,22(a4)	Efecto Slide
	st 30(a4)		hay efecto slide 1-5-92

	and.b #$F0,d1		Parte superior
	beq.s vol_down
	lsr.b #4,d1
	add.b d1,39(a4)		Volumen arriba
	cmp.b #$40,39(a4)
	bmi.s _vol3
	clr.b 30(a4)
	move.b #$40,39(a4)	m ximo

_vol3	move 24(a4),d0		Anterior nota (?11/9/93)
	bsr OK_POTB		Hallar frec. para EFFECT
	move.b 39(a4),d1
	bra.s vol4		Calcular tabla de volumen

vol_down	moveq #$0F,d1
	and.b 31(a4),d1		Parte inferior
	sub.b d1,39(a4)		Volumen abajo
	bpl.s _vol3
	clr.b 39(a4)		m¡nimo
	clr.b 30(a4)
	bra.s _vol3
*******
POSITION	movea.l SEQ(pc),a5	Nueva partitura
	subq.l #1,a5
	move #1,POS
	move.l a5,d0
	moveq #0,d2		Error corregido del 29-04-92
	move.b d1,d2
	add.l d2,d0
	move.l d0,MUS
	moveq #0,d0
	move.b -1(a5),d0	N£mero de partituras
	sub d1,d0
	andi #$FF,d0		Evitar n£meros negativos
	move d0,TRK		   por error del n£mero
	rts		   de repetici¢n
*******			Poner volumen
SET_VOLU	cmp.b #$40,d1
	bls.s vol4	ARREGLADO 5/4/93 (una simple letra)
	moveq #$40,d1
vol4	clr.l d2
	move.b d1,d2
	move.b d2,39(a4)	Volumen en Voice
	lsl.l #8,d2		*256
	add.l VOL_TAB,d2	+ base del volumen
	move.l d2,(a6)		Guardar en VOLx
*	st 20(a4)		Hay nuevo sonido.¨QUE HAGO?
NO_CHANG	rts
*******			Break Pattern
PATTERN_	move #1,POS		Acabar partitura
	rts
*******			Set Filter
SET_FILT	rts
*******			Set Speed
SET_SPEE	tst.b d1
	bne.s .spd
	moveq #1,d1		M¡nima velocidad
.spd	move d1,SPD		Nueva velocidad
	move d1,SPEED
	rts

*********************************************** Efectos de sonido
COMMAND	dc.l ARPEGGIO,PORTAMEN0
	dc.l PORTAMEN1,TONE
	dc.l VIBRATO,NO_COMMA
	dc.l NO_COMMA,TREMOLO
	dc.l NO_COMMA,NO_COMMA
	dc.l SLIDE_VOL,POSITION
	dc.l SET_VOLU,PATTERN_
	dc.l SET_FILT,SET_SPEE

*********************************************** Interpretar efecto
DO_EFFEC	move.b 22(a4),d4	Tipo de efecto
	beq.s ARPEGGIOB
	cmp.b #1,d4
	beq.s PORTUP		Portamento Up
	cmp.b #2,d4
	beq.s PORTDOWN		Portamento Down
	cmp.b #3,d4
	beq TONEPORT		Tone Portamento
	cmp.b #4,d4
	beq VIBRATOB		Vibrato
	cmp.b #7,d4
	beq TREMOLOB		Tr‚molo
	cmp.b #$A,d4
	beq sigue_slide		Slide Volumen
	rts

*********************************************** Portamento arriba
PORTUP	clr.l d5
	move.b 23(a4),d5
	move 24(a4),d0
	sub d5,d0		Bajar nota
	cmp #113,d0		Comprobar l¡mite
	bpl.s OK_PORT
	moveq #113,d0
	bra.s OK_PORT

*********************************************** Portamento abajo
PORTDOWN	clr.l d5
	move.b 23(a4),d5
	move 24(a4),d0
	add d5,d0		Subir nota
	cmp #856,d0
	bmi.s OK_PORT
	move #856,d0
*	bra.s OK_PORT

OK_PORT	move d0,24(a4)		Poner nueva nota
OK_POTB	lsl #2,d0
	move.l 0(a1,d0),26(a4)	Nueva Frecuencia
	rts

*********************************************** Arpeggio
ARPEGGIOB	clr.l d0
	move.b 21(a4),d0
	divs #3,d0
	swap d0
	tst.b d0
	beq.s ARP_ROUT2
	cmp.b #2,d0
	beq.s ARP_ROUT1

ARP_ROUT0	clr.l d2
	move.b 23(a4),d2
	lsr.b #4,d2
	bra.s ARP_ROUT3

ARP_ROUT1	clr.l d2
	move.b 23(a4),d2
	andi #$F,d2
	bra.s ARP_ROUT3

ARP_ROUT2	move 24(a4),d0
	bra.s END_ARP_0

ARP_ROUT3	lsl #1,d2
	move 24(a4),d1
	lea ARPEGGIOT(pc),a2
	moveq #36,d3
ARP_LOOP	move 0(a2,d2),d0
	cmp (a2)+,d1
	bge.s END_ARP_0
	dbra d3,ARP_LOOP
FINI	rts

END_ARP_0	addq.b #1,21(a4)
	bra.s OK_POTB

*********************************************** Tone Portamento
TONEPORT	move.b 33(a4),d0	Velocidad del Tone
	beq.s TONE1
	move.b d0,36(a4)
	clr.b 33(a4)
TONE1	tst 34(a4)
	beq.s FINI

	clr.l d0
	move.b 36(a4),d0	Velocidad
	tst.b 38(a4)		Direcci¢n
	bne.s TONE2

	add d0,24(a4)		sumar nueva nota
	move 34(a4),d0		ver si lleg¢
	cmp 24(a4),d0
	bgt.s TONE3
TONE4	move 34(a4),24(a4)
	clr 34(a4)
TONE3	move 24(a4),d0
	bra OK_POTB

TONE2	sub d0,24(a4)		restar
	move 34(a4),d0
	cmp 24(a4),d0		ver si lleg¢
	blt.s TONE3
	bra.s TONE4

*********************************************** Vibrato
VIBRATOB	move.b 37(a4),d0	Ver Info vibrato
	beq.s VIB1
	move.b d0,33(a4)	Guardar en command
VIB1	move.b 32(a4),d0	Leer Offset vibrato
	lea VIBRATOT(pc),a2	Tabla de vibratos
	lsr #2,d0
	andi #31,d0
	clr.l d2
	move.b 0(a2,d0),d2	Leer valor de tabla
	move.b 33(a4),d0	Vibrato-command
	andi #$F,d0		Tama¤o de vibrato
	mulu d0,d2
	lsr #6,d2
	move 24(a4),d0		Leer nota actual
	tst.b 32(a4)		Seg£n offset vibrato
	bmi.s VIBN
	add d2,d0		Positivo, sumar
	bra.s FINVIB
VIBN	sub d2,d0		Negativo, restar
FINVIB	move.b 33(a4),d1	Command vibrato
	lsr #2,d1
	andi #%111100,d1
	add.b d1,32(a4)		Sumar a offset
	bra OK_POTB		Poner nueva nota

*********************************************** Tr‚molo
TREMOLOB	move.b 37(a4),d0	Ver Info tr‚molo
	beq.s .old
	move.b d0,33(a4)	Guardar en command
.old	moveq #0,d1
	moveq #$1f*4,d0
	and.b 32(a4),d0
	lsr #2,d0
	lea VIBRATOT(pc),a1	Tabla de tr‚molos
	move.b 0(a1,d0),d1	Leer valor de tabla
	moveq #$0F,d0
	and.b 33(a4),d0
	mulu d0,d1
	lsr #6,d1
	move.b 39(a4),d0	Volumen
	tst.b 32(a4)
	bmi.s .vibmin
	add d1,d0
	bra.s .vib2
.vibmin	sub d1,d0
.vib2	bpl.s .ko0
	moveq #0,d0
	bra.s .go
.ko0	cmp #$40,d0
	ble.s .go
	moveq #$40,d0
.go	move.b d0,39(a4)
	moveq #-16,d0
	and.b 33(a4),d0
	lsr.b #2,d0
	add.b d0,32(a4)
	move 39(a4),d1
	bra vol4		Poner nuevo volumen

*********************************************** Generar tablas de frecuencias
GEN_FRQ	clr.l d5
	move frec_base(pc),d5	Base de frecuencias
	clr.l d0
	move tune(pc),d0
	mulu d0,d5		por el tono
	add.l d5,d5		*2
*	add.l d5,d5		*4 si oversampling
	clr.l d0
	move speed_DMA,d0	frecuencia
	lsr.l d0,d5
	lea FRQ,a0		base de frecuencias
	addq #4,a0		?
	moveq #1,d0
.ml1	clr.l d2
	move d0,d2		nota
	lsl.l #4,d2		*16
	move.l d5,d3
	divu d2,d3
	move d3,(a0)+
	clr d3
	divu d2,d3
	move d3,(a0)+
	addq #1,d0
	cmp #1024,d0
	blt.s .ml1
	rts

*********************************************** Poner nueva paleta de colores
EX_PON_PALETA:
	Vsync		Esperar Vbl
	tst ex_color
	beq.s .alta
	Setpalette #NEO+4	Poner paleta de colores
*	move.l #NEO+4,-(sp)
*	move #16,-(sp)
*	move #0,-(sp)
*	move #93,-(sp)
*	trap #14
*	lea 10(sp),sp
	bra.s .fin
.alta	Setpalette #PI3+2	Poner paleta de colores
.fin	Vsync		Esperar asignaci¢n colores
	Vsync		Esperar asignaci¢n colores
	Vsync		Esperar asignaci¢n colores
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	Vsync		Esperar Vbl
	rts

*********************************************** Generar v£metros
*GRIS	equ	$D555D555
*GRIS2	equ	$AAABAAAB
*CLOR	equ	$7FFE0000
*LLENO	equ	$80018001
*LLENO2	equ	-1

GEN_VUM	lea NEO_VUM,a0		Direcci¢n inicial
	moveq #32,d7		N£mero de v£metros

loop_gen_vum	moveq #32,d6		N£mero de niveles
	move d7,d5		N£mero de negros a pintar
	subq #1,d5		menos 1 para dbra
	bmi.s pinta_vum		no hay parte negra
****************
	move ex_color(pc),d0	Para acelerar
loop_negro	moveq #3,d4		Tama¤o de nivel
	moveq #-1,d2		M scaras de dibujo
	tst d0
	beq.s loop_nivel_n
	moveq #0,d2

loop_nivel_n	move.l d2,(a0)+

	dbra d4,loop_nivel_n	Todo el nivel negro
	dbra d5,loop_negro	Todos los niveles negros
****************
pinta_vum	move d7,d5		Ahora, parte llena
	sub d5,d6		resto, lleno
	beq sigue_gen_vum	Caso del primero
	subq #1,d6		por el dbra

	move.l #LLENO,d2	M scaras azul alta
	moveq #LLENO2,d3
	move.l #GRIS,d0		M scaras rojo alta
	move.l #GRIS2,d1
	tst ex_color
	beq.s ver_si_tramo
	move.l #CLOR,d2		M scaras azul baja
	move.l d2,d3
	moveq #0,d0		M scaras rojo baja
	move.l d2,d1
****************
ver_si_tramo	cmp tramo(pc),d6	Ver si rojo o azul
	bls.s parte_azul	ir a pintar de azul

	moveq #1,d4		Tama¤o de nivel
	tst ex_color
	beq.s pinta_rojo
	moveq #0,d4
****************
pinta_rojo	move.l d0,(a0)+
	move.l d1,(a0)+
	tst ex_color
	beq.s sigue_loop_rj
	clr.l (a0)+		La separaci¢n negra en color
	clr.l (a0)+

sigue_loop_rj	dbra d4,pinta_rojo	Todo el nivel rojo
	tst ex_color
	bne.s repite_nivel_rj
	move.l d3,-4(a0)	adefesio de separacion

repite_nivel_rj	dbra d6,ver_si_tramo	Todos los niveles llenos
****************
parte_azul	move ex_color(pc),d0	para acelerar
parte_azul_l	moveq #1,d4		Tama¤o de nivel
	tst d0
	beq.s pinta_azul
	moveq #0,d4

pinta_azul	move.l d2,(a0)+		Barrita azul
	move.l d3,(a0)+
	tst d0
	beq.s sigue_azul
	clr.l (a0)+		La separaci¢n negra en color
	clr.l (a0)+

sigue_azul	dbra d4,pinta_azul	Un nivel azul
	dbra d6,parte_azul_l	Todos los niveles azul
sigue_gen_vum	dbra d7,loop_gen_vum	Para todos los v£metros
	rts

*********************************************** Hacer la tabla de volumen
VOLUMENES	lea VOLUMEN-256,a0
	move #512+256,d0
.loop1	move.b #$80,(a0)+
	dbra d0,.loop1

	move.l #VOLUMEN+256,d0	Direcci¢n de las tablas
	andi.l #$FFFFFF00,d0	M£ltiplo de 256
	move.l d0,VOL_TAB	guardar direcci¢n de la tabla
	move.l d0,a0		Generaci¢n tabla de volumen
	move.l ex_machine(pc),d7	maquina actual
	move d7,d6		Subversion
	swap d7
	clr.l d0		Contador de 256
.l0	move.l d0,d1
	lsl.l #8,d1
	move #$FF,d2		Contador de 256
	clr.l d3
	move #$80,d3
	move d0,d4
	lsr #1,d4
	sub d4,d3
.l1	cmp #_MCH_STe,d7	Es un STe?
	bne.s .noSTe
	cmp #_MCH_MEGASTe,d6
	beq.s .noSTe
	move.b d3,d5		Poner valor
	lsr.b #1,d5		ya dividido por 2
	move.b d5,(a0)+
	bra.s .sigue
.noSTe	move.b d3,(a0)+
.sigue	swap d3
	add.l d1,d3
	swap d3
	dbra d2,.l1
	addq #4,d0
	cmp #257,d0
	blt.s .l0
	rts

*********************************************** Presentar la pantalla
EX_PON_PANTALLA	Physbase		Hallar direcci¢n f¡sica
	movea.l d0,a0		Direcci¢n de pantalla f¡sica
	tst ex_color
	beq.s .alta
	lea NEO+128(pc),a1	Direcci¢n pantalla a copiar
	bra.s .sigue
.alta	movea.l #PI3+34,a1
.sigue	move.l #32000/4-1,d0	Tama¤o
.pan1	move.l (a1)+,(a0)+	Copiar pantalla
	dbra d0,.pan1
	rts

*********************************************** Encriptar el texto
*	bsr ENCRIPTA		Desencripta el texto
*ENCRIPTA	lea INIDAT(pc),a0
*	move #(FINDAT-INIDAT)/4-1,d0
*.loop	eori.l #"JFJF",(a0)+
*	dbra d0,.loop
*	rts
*********************************************** Campos de datos

	DATA

INIDAT	dc.b "*DEF"
tune	dc.w $5C		tono
frec_base	dc.w 49		Base de frecuencias
speed_DMA	dc.w _FRQ		Velocidad del DMA
speed_DMA_TT	dc.w 3		Velocidad defecto en TT
ex_residente	dc.w 0		Indica la residencia
largo_programa	ds.l 1		!!!
error0	dc.b CR,LF,"Este programa no funciona",CR,LF,"en est",0
error1	dc.b CR,LF,"Pulsa para salir...",0
error_maquina	dc.b "e ordenador.",0,0
error_pantalla	dc.b "a resoluci¢n.",0
ex_machine	ds.l 1		Galleta de m quina
ex_resolucion	ds.w 1		Resoluci¢n en el arranque
ex_color	ds.w 1		Qu‚ versi¢n est  funcionando
ex_paleta	ds.l 16		Paleta de colores
VBREC	dc.w VBRE		Contador para Records
VBCONT	dc.w VBLS		Contador de Vbls
RESO	dc.w 0		Resoluci¢n original en color
FIN	dc.w 0		Bandera de final de canci¢n
SIFIN	dc.w -1		Modo de reproducci¢n
COMODIN	dc.b 5,"*.MOD",0	Comando por defecto
FIN_COMODIN:

ANCHO_COL	equ 40		Macro para TEXTO1 (color)
TEXTO1	dc.b ESC,'Y',32+24,32+1	(ANCHO_COL-20)/2
NAM	ds.b 20
	dc.b 0

TEXTO9	POSIC 22,24		Camino
TOTALPOSIC	equ 8
iniposic:
TEXTO2	POSIC 37,19		M xima de partituras
TEXTO3	POSIC 37,20		M xima de posiciones
TEXTO4	POSIC 34,20		Posiciones
TEXTO5	POSIC 34,19		N£mero de partitura
TEXTO6	POSIC 37,21		Velocidad
TEXTO7	POSIC 37,22		Tune
TEXTO8	POSIC 24,8		Modo de reproducci¢n
TEXTO10	POSIC 24,11		M¢dulo a tocar
TEXTO11	POSIC 24,9		Tipo de m¢dulo

modo_normal	dc.b "Normal",0
modo_loop	dc.b " Loop ",0

tipo_MK	dc.b "M.K.",0
tipo_SNDT	dc.b "SNDT",0
tipo_FLT4	dc.b "FLT4",0

NOMOUSE	dc.b $12		Parar Rat¢n
SIMOUSE 	dc.b $08		Sigue Rat¢n
	even
buffer_tec	dc.w $00		Buffer del teclado
VELOCI	dc.w 0		Velocidad
CNT	dc.w 0		Contador de cuadros
PART	dc.w $80		Partitura actual
VUML	dc.w 1		V£metros
VUMR	dc.w 1
VUMLREC	dc.w 32		Records de v£metros
VUMRREC	dc.w 32		HIGHV/ALTOV
ANTVUML	dc.w 32
ANTVUMR	dc.w 32

AFIRMA	dc.b ESC,'p',0		POSITIVO
NIEGA	dc.b ESC,'q',0		NEGATIVO

	dc.w $358,$358
ARPEGGIOT	dc.w $358,$328,$2FA,$2D0,$2A6,$280,$25C,$23A,$21A,$1FC,$1E0
	dc.w $1C5,$1AC,$194,$17D,$168,$153,$140,$12E,$11D,$10D,$FE
	dc.w $F0,$E2,$D6,$CA,$BE,$B4,$AA,$A0,$97,$8F,$87,$7F,$78
	dc.w $71,0,0,0

VIBRATOT	dc.b $00,$18,$31,$4A,$61,$78,$8D,$A1
	dc.b $B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
	dc.b $FF,$FD,$FA,$F4,$EB,$E0,$D4,$C5
	dc.b $B4,$A1,$8D,$78,$61,$4A,$31,$18

TAB_HEX	dc.b 16,17,18,19,20,21,22,23,24,25,'ABCDEF',0

	even
DT	ds.b 30		Buffer para Gemdos
NAME	ds.b 14
ini_texto_color	dc.b ESC,'b',2,ESC,'c',3,0 Textos iniciales

_fichero	ds.b 12		Nombre del fichero leido
	dc.b 0
	even
_basepage	ds.l 1		Apuntar a Basepage
_camino	ds.l 1		Apuntar a comando
_comando	ds.b 128		Comando
_path	ds.b 128		Camino por defecto
_drive_defecto	ds.w 1		Drive por defecto
PISTA	ds.w 1		Partitura actual
TOTALTR	ds.w 1		M ximo n£mero de partituras
SPEED	ds.w 1		Velocidad (contador)
SPD	ds.w 1		Velocidad actual
POS	ds.w 1		Posici¢n en partitura
TRK	ds.w 1		Contador de partitura
	even
SEQ	ds.l 1		Apunt. a orden de partituras
PAT	ds.l 1		Apunt. a partituras
MUS	ds.l 1		Apunt. en orden de part.
ADD_IN_P	ds.l 1		Apunt. dentro de partitura
NBR_INS	ds.w 1		N£mero de instrumentos
POSTRE	ds.l 1		Direcci¢n barra treble
POSBAS	ds.l 1		Direcci¢n barra bass
POSLEF	ds.l 1		Direcci¢n barra left
POSRIG	ds.l 1		Direcci¢n barra right
POSVOL	ds.l 1		Direcci¢n barra volumen
POSVUML	ds.l 1		Direcci¢n barra v£metro left
POSVUMR	ds.l 1		Idem, derecho
SVBL	ds.l 1		Guardar vector VBL
STEC	ds.l 1		Rutina del teclado
CUADRO1	ds.l 1
CUADRO2	ds.l 1
waitc	ds.w 1		Contador de espera
n_frames	dc.w FRAMES		N£mero de cuadros
l_frames	dc.w LFRAME_2		Longitud de los cuadros
l_frames_e	dc.w LFRAME_2/2-1	Idem, para rutina AMIGA
tramo	dc.w 21 (HIGHV/ALTOV*2/3)	Tramo de rojo en v£metro
highv_altov	dc.w 32		Para muchas constantes
ancho	dc.l 160		ANCHO
ancho_4	dc.l 160-4		ANCHO-4
largo_buffer	dc.l 0		Largo de los buffers
_cuadros	ds.l 2		Cuadros a tocar
ant_conterm	ds.b 1		Anterior configuraci¢n teclado
	even
* FORMATO DE LOS VOICE
* +0.L : Tama¤o del sample
* +4.L : Inicio del sample
* +8.L : Inicio para Loop
* +12.L : Frecuencia
* +16.L : Frecuencia en el Loop (es la misma, claro)
* +20.B : Bandera de si sonido (1) o libre (0)
* +21.B : Contador para Arpeggio
* +22.B : Tipo de efecto:0:Arpeggio. 1:Port.Up. 2:Port.Down. 3:Tone. 4:Vibr.
*	7:Tr‚molo. A:Slide Vol.
* +23.B : Offset para 24.W
* +24.W : Nota
* +26.L : Nueva frecuencia despues del efecto
* +30.B : Bandera de si efecto
* +31.B : Antigo slide volumen
* +32.B : Offset del vibrato y Tr‚molo
* +33.B : Comando del Vibrato, Tone y Tr‚molo
* +34.W : Nota destino en Tone
* +36.B : Velocidad del Tone
* +37.B : Informacion del vibrato y Tr‚molo
* +38.B : Direccion del Tone
* +39.B : Volumen
* +40.W : Numero de instrumento
LVOICE	equ 42
VOICE0	ds.b LVOICE
VOICE1	ds.b LVOICE
VOICE2	ds.b LVOICE
VOICE3	ds.b LVOICE
REGIS	ds.l 9
AREA	ds.l 5

* FORMATO DEL AREA DE TRABAJO
* Dn: Tama¤o del sample
* An: Inicio del sample
* Vn: Frecuencia de reproduccion
* Ln: Tama¤o del loop = Inicio del sample en Loop
* Fn: Frecuencia en loop = Vn o 0
* VOLn: Direcci¢n de la tabla de volumen
V0	ds.l 1
L0	ds.l 1
F0	ds.l 1
VOL0	ds.l 1
V1	ds.l 1
L1	ds.l 1
F1	ds.l 1
VOL1	ds.l 1
V2	ds.l 1
L2	ds.l 1
F2	ds.l 1
VOL2	ds.l 1
V3	ds.l 1
L3	ds.l 1
F3	ds.l 1
VOL3	ds.l 1

* FORMATO DE LOS INS
* +00.L : Tama¤o del sample
* +04.L : Inicio del sample
* +08.L : Valor de loop
* +12.W : Volumen
LINS	equ 16
INS	ds.b 32*LINS
VOL_TAB	ds.l 1
MUZEXX	ds.l 1

NEO	INCBIN TABLERO.NEO
PI3	INCBIN TABLERO.PI3
	dc.l 0
FINDAT:

*********************************************** Area de datos no inicializada
	BSS

	ds.l 128		Espacio para la pila
STACK	ds.l 1
	ds.l 2
	ds.b 256
VOLUMEN	ds.b 256+256
	ds.b 256*$40
	ds.l 2
FRQ	ds.l 1025
	ds.l 2
NEO_VUM	ds.b 16900		Espacio para los v£metros
	ds.l 2
BUFFER	ds.b 64*1024
	ds.l 2
_ex_fin:
* Formato de los .MOD:
*
* +0 a +19	: Nombre del m¢dulo
* +20	: Origen de la lista de instrumentos (31)
*  +0.B	: 20 caracteres con el nombre del instrumento
*  +20.W	:
*  +22.W	: Tama¤o del sample, en palabras
*  +24.W	: Volumen
*  +26.W	: Valor de repetici¢n, en palabras, o 0
*  +28.W	: Tama¤o del loop, en palabras, o 1
* +950.B	: Longitud de la melodia (?)
* +1084	: Partituras

	END
* Fin de Explorer SoundTracker.
