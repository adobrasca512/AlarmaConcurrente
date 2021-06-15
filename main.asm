;
; InterrupcionesEncenderLed.asm
;
; Created: 21/04/2021 11:37:50
; Author : adobr
;

 
; Replace with your application code
.dseg

tiempo: .db 1
.cseg
.EQU Clock = 16000000   ;variables                ;frecuencia de reloj, en Hz
.EQU Baud = 9600      ;variables                  ;velocidad de transmisión deseada (bits por segundo)
.EQU UBRRvalue = Clock/(Baud*16) - 1  ;formula  ;formula para calcula el valor que se colocará en UBRR0H:L
 
;.EQU PIN_LED = 5                        ;Pin de Led de ejemplo, Pin 13 de arduino
   
.ORG 0x0000           
     
	 
	    ;punto de entrada en el inicio del sistema
 jmp main                      ;ir al programa princiapal para saltar el Vector de Interrupciones

.ORG 0x0032         
                ;puntos de entrada en vectores de interrupción para USART0
    JMP USART0_reception_completed    
		 ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
    RETI ;Solo funciona con  interrupciones                           ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
    RETI  ;solo va al porg. principal                              ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
 	
.org 0x0100 ;.org definir un espacio en memoria                   ;Fin del espacio reservado para el Vector de Interrupciones

main:    
    ldi r16,0xff
out DDRB,r16 


 ; push r16

   RCALL init_USART0
				            ;llamada a la funcion de configuración de la USART
 
    SEI 





	loop1:
	;sbi es activar o poner a 1 un pin

	sbi portb,5
	ldi r21, 5; marcamos 250ms
	push r21
	call delay50ms; activo 250ms
	pop r21
	

	lds r20,tiempo; evaluo si hay valores en el puerto serial
	cpi r20,4; comparo con 4 (tiempo de espera si hay valor)
	brne continuar; si no es igual continuamos parpadeando
	push r20
	call delay50ms
	pop r20
	continuar:
	;cb1 es poner a 0 un pin
	cbi portb,5
	push r21
	call delay50ms
	pop r21
	
	rjmp loop1
	
	

init_USART0:                                   
        ;cargar en UBRR el valor para obtener la velocidad de transmisión deseada
        PUSH r16
        LDI R16, LOW(UBRRvalue)     ; Low byte of Vaud Rate ; lo que resulto de la operacion del r16 y abarca 16 bits
        STS UBRR0L, R16             ; UBRR0L - USART Baud Rate Register Low Byte ; guarda en memoria ram
        LDI R16, HIGH(UBRRvalue)    ; High byte of Vaud Rate
        STS UBRR0H, R16             ; UBRR0H - USART Baud Rate Register High Byte
        ;habilitar recibir y transmitir, habilitar interrupcion USART0 "Rx terminado" (No las: UDR vacío, Tx terminado)
        ldi r16, (1<<RXCIE0)        ; RX Complete Interrupt Enable
        ori r16, (1<<RXEN0)         ; Receiver Enable ; ori suma
        ori r16, (0<<TXEN0)        ; Transmitter Enable
        STS UCSR0B, R16             ; UCSR0B - USART Control and Status Register B ; recibe la info y activa el puerto serial
        ; configure USART 0 como asíncrono, establezca el formato de trama ->
        ; -> 8 bits de datos, 1 bit de parada, sin paridad
        ldi r16, (1<<UCSZ01)        ; Character Size = 8 bits ; si le dices 3 es el character sixe
         ori r16, (1<<UCSZ00)  
		    ori r16, (0<<UPM01)         ; Receiver Enable ; ori suma
        ori r16, (0<<UPM00)        ; Transmitter Enable
		ORI r16, (0<<USBS0)
	    STS UCSR0C, R16             ; UCSR0C - USART Control and Status Register C
        POP r16
	
        RET
		/****************************
    Funcion de atencion de la interrupcion de Dato recibido por USART
    Se dispara cuando un nuevo byte está listo en el registro UDR0
****************************/
USART0_reception_completed :
        PUSH R16   ; funcion para recibir info
        IN R16, SREG       ;registro de control ; Copia de seguridad SREG. OBLIGATORIO en las rutinas de manejo de interrupciones
        PUSH R16       
        ; ** Aqui empieza el cuerpo de la funcion de atencion de la interrupcion
        LDS R16, UDR0               ; recoger el byte recibido para procesarlo
        ldi r20,4
        sts tiempo, r20
		push r16
	    andi r16,0b00000001
		cpi r16,0b00000001
		breq encender
		cbi portb,0
		rjmp fin
		;rcall preparativos
		encender: 
		sbi portb,0
		fin:
		pop r16
	

 sts UDR0,r16
	    POP R16
        OUT SREG, R16               ; Recuperar SREG de la copia de seguridad anterior
        POP R16
        RETI                        ; RETI es OBLIGATORIO al regresar de una rutina de manejo de interrupciones


 
  
delay50ms:
	push YL
	push YH
	IN YL, SPL

	IN YH, SPH
	push r16
	push r18
	push r19
	push r20
	ldd r16,y+5

loop:
    ldi  r18, 21
    ldi  r19, 75
    ldi  r20, 191
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
	dec r16
	brne loop
	pop r20
	pop r19
	pop r18
	pop r16
	pop YH
    pop YL
ret
	
