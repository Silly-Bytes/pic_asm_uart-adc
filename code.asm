    list p=16f876A

; Declaración de direcciones de memoria
; Datasheet pagina 17, figura 2-3
PORTA      EQU 0x05
PORTB      EQU 0x06
TRISA      EQU H'85'
TRISB      EQU H'86'
TRISC      EQU H'87'
RP0        EQU H'05'
RP1        EQU H'06'
STATUS     EQU H'03'
DATO       EQU H'21'
ADCON0     EQU H'1F'
ADCON1     EQU H'9F'
PIR1       EQU H'0C'
INTCON     EQU H'0B'
PIE1       EQU H'8C'
ADRESH     EQU H'1E'
ADRESL     EQU H'9E'
SPBRG      EQU H'99'
TXSTA      EQU H'98'
RCSTA      EQU H'18'
TXREG      EQU H'19'
RCREG      EQU H'1A'
OPTION_REG EQU H'81'
IRP        EQU H'07'

VAR1       EQU H'20'
VAR2       EQU H'A0'
VAR3       EQU H'110'
VAR4       EQU H'190'

; Inicialización de registros de direccionamiento indirecto
; Datasheet pagina 31
INDF       EQU H'0'
FSR        EQU H'04'

; Variables propias a usarse en el programa
LECTURA1   EQU D'40'
LAZOS1     EQU H'7F'
LECTURA2   EQU D'40'
LAZOS2     EQU H'7E'
LECTURA3   EQU D'48'
LAZOS3     EQU H'7D'
LECTURA4   EQU D'48'
LAZOS4     EQU H'7C'
GRU        EQU 0x15
MED        EQU 0x20
FIN        EQU 0x20
REG1       EQU H'22'
REG2       EQU H'23'
REG3       EQU H'24'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inicialización y configuración
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT
    org 0

    ; Selección BANCO 1
    ; Datasheet pagina 16, sección 2.2
    BSF STATUS,RP0
    BCF STATUS,RP1

    ;;; Configuración de puertos IO
    ;;; Datasheet pagina 41
    ; El puerto A es de entrada
    MOVLW   B'00111111'
    MOVWF   TRISA
    ; El puerto B es de entrada
    MOVLW   B'00000000'
    MOVWF   TRISB
    ; Puerto C: pin TX es salida, pin RX es entrada
    MOVLW   B'10001111'
    MOVWF   TRISC

    ;;; Configuración de puerto ADC
    ; Todas las entradas son analógicas
    ; Datasheet pagina 127
    MOVLW   B'10000000'
    MOVWF   ADCON1


    ;;; Configuración UART
    ; Banco 1
    BSF STATUS,RP0
    BCF STATUS,RP1
    ; 19200 Baudios
    ; Datasheet pagina 114, tabla 10-4
    MOVLW   .12
    MOVWF   SPBRG
    ; Registro de transmisión
    MOVLW   B'10100100'
    MOVWF   TXSTA
    ; Banco 0
    BCF STATUS,RP0
    BCF STATUS,RP1
    ; Registro de recepción
    MOVLW   B'10010000'
    MOVWF   RCSTA


;=======  RECEPCION SERIAL ==========================

    BSF RCSTA,4     ;HABILITA RECEPCION SETEANDO BIT CREN

LLENAS
    BTFSS   PIR1,5      ;PRUEBA EL BIT RCIF=1 DE RECEPCION COMPLETA
    GOTO    LLENAS      ;PERMANECE EN EL LAZO HASTA QUE INGRESE EL DATO

    MOVF    RCREG,W     ;SE TRANSFIERE EL DATO RECIBIDO HACIA EL W
    MOVWF   PORTB       ;SEGUIMOS EN EL BANK0


;**** realizar una conversion A/D solo luego de  ingresar un dato****
;============== PREPARA CONVERSION A/D ==========================

;============== seleccion de canal analogico usando RCREG ==========

    BCF STATUS,RP0
    BCF STATUS,RP1  ;BANK0;FOSCI/8..CANAL segun RCREG..A/D OPERANDO

    MOVWF   ADCON0      ;se transfiere desde W hacia ADCON0
                            ;valores permitidos son 65 73 81 89 97 105 113 121
    BCF PIR1,6      ;BORRA ADIF DEL REGISTRO PIR1

;===== FIN DE LA CONFIGURACION DEL A/D ===============

    BSF STATUS,RP0
    BCF STATUS,RP1  ;BANK1
    BSF INTCON,7
    BSF PIE1,6      ;COLOCA 1 EN ADIE Y GIE

    BCF STATUS,RP0
    BCF STATUS,RP1  ;BANK 0

    BSF ADCON0,2        ;INICIA LA CONVERSION

ESPER1  BTFSS   PIR1,6  ;ESPERA FIN DE CONVERSION
    GOTO    ESPER1

;********************  FIN DE LA CONVERSION A/D *********

    BCF PIR1,6      ;BORRA ADIF
;==========================================================
;===================== TRANSMISION SERIAL ===============================

    BSF STATUS,RP0
    BCF STATUS,RP1
    MOVF    ADRESL,W    ;CARGARA UN BYTE BAJO
    BCF STATUS,RP0
    BCF STATUS,RP1  ;BANK0

    MOVWF   TXREG       ;TRANSMITE BYTE BAJO

    BSF STATUS,RP0
    BCF STATUS,RP1  ;BANK1
ESPE1
    BTFSS   TXSTA,1     ;PRUEBA TRMT,SI BUFFER ESTA VACIO
    GOTO    ESPE1
;===============================================================
    BCF STATUS,RP0
    BCF STATUS,RP1  ;BANK0

    MOVF    ADRESH,W        ;SE TRANSMITIRA EL BYTE ALTO
    MOVWF   TXREG

    BSF STATUS,RP0
    BCF STATUS,RP1  ;BANK1

ESPE11
    BTFSS   TXSTA,1
    GOTO    ESPE11
    BCF TXSTA,1

    ;=========== FIN DE TRANSMISION DE LOS DOS BYTES ===============


    GOTO    INICIO

DEMORA          ;ASEGURARSE DE ESTAR EN EL BANK0
    MOVLW   GRU ;GRU,REG,ETC ESTAN EN BANK0
    MOVWF   REG1
DEM3
    MOVLW   MED
    MOVWF   REG2
DEM2
    MOVLW   FIN
    MOVWF   REG3
DEM1
    DECFSZ  REG3
    GOTO DEM1
    DECFSZ  REG2
    GOTO DEM2
    DECFSZ  REG1
    GOTO    DEM3
    RETLW   0

WAIT
    BCF STATUS,RP0
    BCF STATUS,RP1
    MOVLW   FIN
    MOVWF   REG3
CHANCE
    DECFSZ  REG3
    GOTO    CHANCE
    RETLW   0


    END
