# PIC16F876A conversión analógica digital + UART (Ensamblador)

NOTE: This post is available in Spanish only. Please use a software translator.


[He dejado de usar microcontroladores PIC por los motivos explicados en este
post](http://silly-bytes.blogspot.com/2016/06/from-pic-to-avr.html); Pero voy a
dedicar este post para tratar y explicar un programa sencillo escrito en
ensamblador para el **PIC16F876A**.

El objetivo es el siguiente:

Se desea usar el microcontrolador para llevar a cabo la conversión
analógica-digital de una tensión variable (un LDR o un potenciómetro por
ejemplo) y transmitir el resultado usando la UART. Además debe ser posible
recibir por la UART un par de bytes que deben alterar la configuración del
Conversor Análogo Digital (DAC) interno del microcontrolador para, por ejemplo,
cambiar el canal de entrada de la señal analógica o modificar la velocidad del
reloj de conversión.

El código ha sido ensamblado con el ensamblador de GNU *gpasm* del juego de
herramientas [gputils](http://gputils.sourceforge.net/), pero debería ser
perfectamente compatible con las herramientas MPLAB de Microchip que no uso
porque [odio los
IDEs](http://silly-bytes.blogspot.com/2016/03/why-do-i-hate-ides.html). En
cualquier caso la explicación y el 99% del código debería ser útil sin
modificación alguna.

Este post se deberá leer en paralelo junto con el *datasheet* del
microcontrolador en cuestión **PIC16F876A** que se puede encontrar aquí:
http://ww1.microchip.com/downloads/en/DeviceDoc/39582C.pdf

El código completo [se encuentra
aquí](https://github.com/Silly-Bytes/pic_asm_uart-adc/blob/master/code.asm).

Empezamos examinando y explicando el código:

    list p=16f876A

La primera linea le dirá al ensamblador los mapas de memoria que el enlazador
deberá usar (el microcontrolador que estamos usando).

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

En el Datasheet, pagina 17, figura 2-3 se puede ver el mapa completo de memoria
del microcontrolador. En estas lineas declaramos los nombres y direcciones (en
hexadecimal) de los mismos para usarlos en el código con más facilidad. La
palabra `EQU` asigna el nombre de la izquierda al valor de la derecha. Para
declarar un valor hexadecimal se usa el prefijo `0x`.
