;---------------------------------------;
;    Random Number Generation (LFSR)    ;
;                                       ;
;---------------------------------------;

; - This is a macro to print the newline
newline  MACRO
	     LEA DX, NL      ;to pass the address of NL
	     MOV  AH, 09h    ;21h OS(DOS) interrupt
	     INT  21h        ;AH=09 print string
         ENDM

; - This is a macro to print a string;
writemsg  MACRO string
	      LEA  DX, string     ;to pass the address of MSG
	      MOV  AH, 09h    ;21h OS(DOS) interrupt
	      INT  21h        ;AH=09 print string
          ENDM
	
.MODEL small ; memory model definition, in this case small
	
;Data segment with public data
.DATA
    LF       EQU  0Ah         ;ASCII code for Line Feed  
    CR       EQU  0Dh         ;ASCII code for Carriage Return
	NL       DB  CR,LF,'$'    ;New line  
	VARIN    DW  ?            ;Variable for reading number 
	HANDLER  DW  ?                ;This for the file handler	
	FNAME    DB  "res.txt",'$'   ;File name termniate with $
    FILE     DB  "res.txt",0     ;File name must terminate with 0
	VAROUT   DW  ?            ;Variable for printing number
	STORE	 DW  ?
	STOREV1	 DW  ?            ;variable for storing values of the 1st column
	STOREV2	 DW  ?            ;variable for storing values of the 2nd column
	RANDOM1  DW  ?            ;Variable to contain the random number
	RANDOM2	 DW  ?
	ONE		 DW	 ?				; for 1 and -1
    MSG1     DB  "Input error...",'$'    ;This is a string
	MSG2     DB  "Try again: ",'$'
	MSG3     DB  "Program to generate random numbers.",'$'
	MSG5     DB  "     ",'$'
	MSG6     DB  "Enter the number of random numbers to generate: ",'$'

;Stack segment, define as stack
.STACK 400h

;Code segment 
.CODE


;This is the core of the program, we define a MAIN procedure
;The procedure is FAR. A FAR procedure can be called everywhere
MAIN    PROC FAR 
    
    MOV  AX,@DATA   ;Initialization of Data segment passing
    MOV  DS,AX      ;Through the register AX
	
    writemsg MSG3
	newline

	CALL OPEN_FILE

next1:
    CALL RAND_SEED1  ;randomization for the 1st column
	CALL RAND_SEED2  ;randomization for the 2nd column

next2:
    newline	
    writemsg MSG6
	CALL INPUT_NUM     ;input the number of entries
	MOV CX, VARIN      
	XOR BX, BX
	JMP posNum         ;jump to print the first value of the sequence as 0
cycle:
    CALL RAND1       
	MOV BX, STOREV1    ;move stored value to BX
	ADD  BX, ONE       ;add to BX randomized 1 or -1
	MOV  STOREV1, BX   ;store this value in variable STOREV1
	MOV  AX, RANDOM1   
	CMP STOREV1, 0000h ;check if the value is positive or negative or zero
	JZ	 posNum         ;if zero print to DOS in posNum
	JG	 posNum         ;if it is positive print to DOS in posNum
	
negNum:
	newline
	MOV AH,02h          ;however, if it is negative print the symbol '-' before the value
	MOV DL, '-'
	INT 21h

flow:
	PUSH CX
	PUSH DX
	
	
	XOR CX, CX         ;by use of register CX, take the negative value of STOREV1 
	XOR DX, DX
	MOV CX, STOREV1    ;and perform the 2's complement to get the positive number
	NOT CX
	INC CX
	
	MOV DX, CX
	MOV VAROUT, DX     ;print the negative number using '-' and 2's complement
	CALL PRINT_NUM
	
	POP DX
	POP CX
	JMP cycle2      ;jump directly to cycle2

	
posNum:
	MOV DX, STOREV1
	MOV  VAROUT, DX
	newline
	CALL PRINT_NUM
	;JMP posNum2
	
cycle2:
	CALL RAND2
	MOV AX, RANDOM2   ;take the randomised number from rand_seed 2 and store it in AX
	MOV BX, STOREV2    ; move the variable STOREV2 corresponding to the 2nd column to BX
	ADD  BX, ONE        ;add randomised +1 or -1 
	MOV  STOREV2, BX    ;store the value in STOREV2
	
	CMP STOREV2, 0000h  ;make the same operations by checking if the number is 0, positive or negative
	JZ	 posNum2
	JG	 posNum2
	
negNum2:
	writemsg MSG5
	MOV AH,02h
	MOV DL, '-'
	INT 21h

flow2:
	PUSH CX
	
	XOR CX, CX
	MOV CX, STOREV2    ; the same procedure of taking 2's complement
	NOT CX
	INC CX
	
	MOV DX, CX
	MOV VAROUT, DX 
	CALL PRINT_NUM
	 
	POP CX
	JMP NEAR PTR done
	
posNum2:
	MOV DX, STOREV2
	MOV  VAROUT, DX 
	writemsg MSG5
	CALL PRINT_NUM
	
	
done:
	DEC CX
	JNZ cond            ;LOOP couldn't reach the beginning of the cycle so we used the unconditional jump to the conditional jump JMP
    
	
	CALL CLOSE_FILE
	
    MOV  AH,4Ch     ;21h OS(DOS)interrupt.
    INT  21h        ;AH=4Ch is for terminate the process
	
cond:
	JMP NEAR PTR cycle   ; return to the beginning of cycle and repeat
    RET             ;return to the OS
MAIN    ENDP        ;termination of the procedure

;---------------------------------------------;
;    Procedure to generate a random number    ;
;---------------------------------------------;		
RAND_SEED1    PROC NEAR
    
	PUSH AX     ;to save the registers before the call
	PUSH CX
	PUSH DX
	
	MOV  AH, 00h    ;Bios interrupt 1Ah
	INT  1Ah        ;AH=0 read clock tics 
	                ;from midnight, result is in CX:DX
	MOV  RANDOM1, DX

    POP  DX    ;to registers the registers after the call
	POP  CX
	POP  AX
    RET
RAND_SEED1   ENDP

RAND_SEED2    PROC NEAR
    
	PUSH AX     ;to save the registers before the call
	PUSH CX
	PUSH DX
	
	MOV  AH, 00h    ;Bios interrupt 1Ah
	INT  1Ah        ;AH=0 read clock tics 
	                ;from midnight, result is in CX:DX
	MOV  RANDOM2, DX

    POP  DX    ;to registers the registers after the call
	POP  CX
	POP  AX
    RET
RAND_SEED2   ENDP

;---------------------------------------------;
;    Procedure to generate a random number    ;
;---------------------------------------------;		
RAND1    PROC NEAR
        
		PUSH AX      ;to save the registers before the call
		PUSH BX
		PUSH CX
		PUSH DX
		
	    MOV  AX, RANDOM1    ;enter the seed
	    MOV  BL, 2Dh       ;extract the taps
	    AND  BL, AL        ;by masking with AND
	    JNP  odd           ;check the number of ones, 
		
		
		MOV DX, AX         ;use the spare register DX to obtain +1 or -1
		AND DX, 0001h      ;AND DX with 0001h to get 0001h back or 0000h
		CMP DX, 00h        ; check if it's 0000h
		JNE okay           ; if yes, add 1 to it
		ADD DX, 1 
okay:		
		MOV ONE, DX         ;move dx to variable ONE
	    SHR  AX, 01h       ;if even just shift
	    MOV  RANDOM1, AX
	    JMP  rend
	
odd:    MOV DX, AX          
		AND DX, 0001h        ;AND DX with 0001h to get 0001h back or 0000h
		CMP DX, 00h          ; check if it's 0000h
		JNE norm             ;if not equal to 0000h then jump to norm 
		ADD DX, 1            ;if equal to 0000h then add 1
norm:
		NOT DX
	    INC DX              ;take the 2's complement to get -1
		MOV ONE, DX         ;store -1 in variable ONE
		SHR  AX, 01h      ;if odd enter one in the shift
	    OR   AX, 8000h
	    MOV  RANDOM1, AX

rend:   POP  DX
		POP  CX
		POP  BX     ;to registers the registers after the call
        POP  AX
        RET
RAND1    ENDP


RAND2    PROC NEAR
        
		PUSH AX      ;to save the registers before the call
		PUSH BX
		PUSH CX
		PUSH DX
		
	    MOV  AX, RANDOM2    ;enter the seed
	    MOV  BL, 2Dh       ;extract the taps
	    AND  BL, AL        ;by masking with AND
	    JNP  odd2           ;check the number of ones, 
		
		
		MOV DX, AX
		AND DX, 0001h
		CMP DX, 00h
		JNE okay2
		ADD DX, 1 
okay2:		
		MOV ONE, DX
	    SHR  AX, 01h       ;if even just shift
	    MOV  RANDOM2, AX
	    JMP  rend2
	
odd2:    MOV DX, AX
		AND DX, 0001h
		CMP DX, 00h
		JNE norm2
		ADD DX, 1
norm2:
		NOT DX
	    INC DX
		MOV ONE, DX
		SHR  AX, 01h      ;if odd enter one in the shift
	    OR   AX, 8000h
	    MOV  RANDOM2, AX

rend2:   POP  DX
		POP  CX
		POP  BX     ;to registers the registers after the call
        POP  AX
        RET
RAND2    ENDP




;---------------------------------------------------;
;    Procedure to enter unsinged decimal numbers    ;
;---------------------------------------------------;
INPUT_NUM    PROC NEAR
     
	    PUSH AX      ;to save the registers before the call
		PUSH BX
		PUSH CX
		PUSH DX

        MOV VARIN, 0h   ;Varin becomes 0     
	
inbeg:	MOV AH, 01h     ;Dos interrupt, read character
        INT 21h         ;output in AL
	
	    CMP AL, 0Dh     ;compare to carriage return
		JE  inend       ;conditional jump to the end if  
		
		CMP AL, 30h
		JB 	inerr
		
		CMP AL, 39h     ;comapre with character '9'
	    JA  inerr       ;conditional jump to input error if greater than '9'
		
		SUB AL, 30h     ;subtract the ascii of '0', convert character to number
		XOR AH, AH      ;AH = 0 by using XOR
        MOV BX, AX      ;BX now contain the input number
        MOV AX, VARIN   ;we move varin in AX
		MOV DX, 0AH     ;DX = 10
      	MUL DX          ;we multiply by 10
        ADD AX, BX      ;we add  the input decimal digit
        MOV VARIN, AX	;varin is updated to the new value	
		JMP inbeg       ;unconditional jump to the beginning
				
inerr:  newline
        writemsg MSG1
        newline
        writemsg MSG2
		MOV VARIN, 0h   ;Varin becomes 0  
        JMP inbeg       ;;unconditional jump to the beginning
		
inend:  POP  DX      ;to registers the registers after the call
		POP  CX
		POP  BX
		POP  AX   
        RET
INPUT_NUM    ENDP

;---------------------------------------------------;
;    Procedure to print unsinged decimal numbers    ;
;---------------------------------------------------;
PRINT_NUM    PROC NEAR

        PUSH AX      ;to save the registers before the call
		PUSH BX
		PUSH CX
		PUSH DX
         
        MOV  AX, VAROUT   ;we save varout in AX 
        MOV  BX, 0Ah      ;BX = 10
        XOR  CX, CX       ;CX = 0 by using XOR
          
spush:  XOR   DX,DX       ;CX = 0 by using XOR, for DX:AX / BX
        DIV   BX          ;result in AX, reminder in DX
        PUSH  DX          ;Save remainder in the stack
        INC   CX          ;Increment the counter
        CMP   AX, 00h     ;if AX is zero we arrived to the last digit
        JNZ   spush       ;condidional jump if AX is not zero
		                   ;more digit to push in the stack

spop:   POP   DX          ;pick up numbers form stack in reverse order
        ADD   DL, 30h     ;convert number into character
        MOV   AH, 02h     ;Dos interrupt, print character
        INT   21h         ;character in DL
		MOV STORE, DX
		CALL WRITE_FILE
        LOOP  spop        ;loop for the number saved in CX = pushed digits
		
		
		
        POP  DX      ;to registers the registers after the call
		POP  CX
		POP  BX
		POP  AX    
	   
        RET
PRINT_NUM    ENDP

OPEN_FILE 		PROC NEAR
		PUSH AX
		PUSH CX
		PUSH DX
		
		MOV  AH, 3Ch           ;21h OS(DOS)interrupt.
		MOV  CX, 0h            ;AH=3Ch is create a file
		LEA  DX, FILE          ;CX=0h is ordinary file
		INT  21h               ;DX points to filename
		MOV HANDLER, AX

		POP DX
		POP CX
		POP AX

		RET
OPEN_FILE		ENDP

WRITE_FILE		PROC NEAR
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		
		MOV  AH, 40h           ;21h OS(DOS)interrupt.
		MOV  BX, HANDLER       ;AH=40h to write a file
		MOV  CX, 4          ;BX the handler
		DEC  CX
		LEA  DX, STORE           ;CX len of the buffer
		INT  21h  
		
		POP DX
		POP CX
		POP BX
		POP AX
		
		RET
WRITE_FILE		ENDP

CLOSE_FILE		PROC NEAR
		PUSH AX
		PUSH BX
	
		MOV  AH, 3Eh           ;21h OS(DOS)interrupt.
		MOV  BX, HANDLER       ;AH=3Eh to close a file
		INT  21h               ;BX the handler
		
		POP BX
		POP AX
		
		RET
CLOSE_FILE		ENDP

    END MAIN
	
	
