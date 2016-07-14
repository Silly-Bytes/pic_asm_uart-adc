; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
; Daniel Campoverde Carrión [alx741]
; <alx741@riseup.net>



    list p=16f876A


; Declaración de direcciones de memoria
; Datasheet pagina 17, figura 2-3
PORTA      EQU 0x05
PORTB      EQU 0x06
TRISA      EQU 0x85
TRISB      EQU 0x86
TRISC      EQU 0x87
RP0        EQU 0x05
RP1        EQU 0x06
STATUS     EQU 0x03
DATO       EQU 0x21
ADCON0     EQU 0x1F
ADCON1     EQU 0x9F
PIR1       EQU 0x0C
INTCON     EQU 0x0B
PIE1       EQU 0x8C
ADRES0x    EQU H'1E
ADRESL     EQU 0x9E
SPBRG      EQU 0x99
TXSTA      EQU 0x98
RCSTA      EQU 0x18
TXREG      EQU 0x19
RCREG      EQU 0x1A
OPTION_REG EQU 0x81
IRP        EQU 0x07

VAR1       EQU 0x20
VAR2       EQU 0xA0
VAR3       EQU 0x110
VAR4       EQU 0x190

; Inicialización de registros de direccionamiento indirecto
; Datasheet pagina 31
INDF       EQU 0x0
FSR        EQU 0x04


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
    ; El puerto B es de salida
    MOVLW   B'00000000'
    MOVWF   TRISB
    ; Puerto C: pin TX es salida, pin RX es entrada
    MOVLW   B'10001111'
    MOVWF   TRISC

    ;;; Configuración de puerto ADC
    ; Todas las entradas son analógicas
    ; Datasheet pagina 128
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
    MOVLW B'10010000'
    MOVWF RCSTA
    BSF   RCSTA,4



;;; Esperar primer byte de configuración
ESPERAR_CONFIG
    BTFSS   PIR1,5
    GOTO    ESPERAR_CONFIG

    ; Colocar byte recibido en la configuración ADCON0 del conversor ADC
    BCF   STATUS,RP0
    BCF   STATUS,RP1
    MOVF  RCREG,W
    MOVWF ADCON0
    ; Vaciar el bit de recepción
    BCF   PIR1,6



;;; Esperar tiempo de adquisición e iniciar conversión
CONVERTIR
    ; Instrucciones de espera
    NOP
    NOP
    NOP
    NOP
    NOP
    ; Activar conversor
    BSF ADCON0,2

ESPERAR_CONVERSION
    BTFSS   PIR1,6
    GOTO    ESPERAR_CONVERSION
    BCF PIR1,6


; Transmitir el resultado mediante la UART
TRANSMITIR_RESULTADO
    BSF STATUS,RP0
    BCF STATUS,RP1
    ; Transmitir byte bajo del resultado (ADRESL)
    MOVF    ADRESL,W
    BCF STATUS,RP0
    BCF STATUS,RP1
    MOVWF   TXREG
    BSF STATUS,RP0
    BCF STATUS,RP1

; Esperar que el primer byte se transmita
ESPERAR_1
    BTFSS   TXSTA,1
    GOTO    ESPERAR_1
    BCF STATUS,RP0
    BCF STATUS,RP1
    ; Transmitir byte alto del resultado (ADRESH)
    MOVF    ADRESH,W
    MOVWF   TXREG
    BSF STATUS,RP0
    BCF STATUS,RP1

; Esperar que el segundo byte se transmita
ESPERAR_2
    BTFSS   TXSTA,1
    GOTO    ESPERAR_2
    BCF TXSTA,1


    GOTO    CONVERTIR

    END
