IF1 
    INCLUDE C:\TASM\MACRO.MAC  ;macros used for output
ENDIF

DATA SEGMENT PARA PUBLIC 'data'

BOARD DB 0,0,0,0,0  ; active board

FYVALUES DB 24,28,14,7,3  ; values to be checked on a specific row (3 columns)
YVALUES DB 16,8,4,2,1    ; values to be checked on the other 2 rows (1 column)

ZECE DB 10
WIN DB "You won!Congratulations!",0ah,0dh,"$"
RESTART DB "Press Enter to start another game.",0ah,0dh,"$"
SCREEN DB "Press any key to exit the game",0ah,0dh,"$"
NRMOVES DB "Number of moves: ","$"
HOURS DB "Hours: ","$"
MINUTES DB "Minutes: ","$"
SECONDS DB "Seconds: ","$"

;Boards from which to choose
BOARD1 DB 2,2,24,13,19
BOARD2 DB 19,29,25,22,3
BOARD3 DB 28,28,9,16,4
BOARD4 DB 11,1,10,7,15
BOARD5 DB 8,30,31,2,20
BOARD6 DB 3,2,8,27,29
BOARD7 DB 6,3,7,7,20
BOARD8 DB 1,17,18,30,1
BOARD9 DB 6,29,30,28,0
BOARD10 DB 16,7,20,0,4
BOARD11 DB 20,24,4,0,16
BOARD12 DB 0,13,2,9,26
BOARD13 DB 23,8,21,17,23
BOARD14 DB 3,26,1,13,30
BOARD15 DB 11,15,10,2,26
BOARD16 DB 7,24,0,18,10
BOARD17 DB 2,12,31,28,26
BOARD18 DB 2,12,31,28,26
BOARD19 DB 17,4,4,26,17
BOARD20 DB 15,19,25,31,21

MOVES DW 0  ;moves to be counted
ROW DB 0    ; row where to print the hour/minute/column
COL DB 0    ; col where to print the hour/minute/column
PSTRING DW 0  ; string to be printed

DATA ENDS

STCK SEGMENT PARA STACK 'stack' 
	DB 64 DUP ('my_stack')
STCK ENDS

CODE SEGMENT PARA PUBLIC 'code'
ASSUME DS:DATA,CS:CODE,SS:STCK

MAIN PROC FAR

PUSH DS
XOR AX,AX
PUSH AX
MOV AX,DATA
MOV DS,AX

RESTART_GAME:

MOV AX, 0   ;set video mode
MOV AL, 13H ; mode 13h = 320x200 pixels, 256 colors
INT 10H    

MOV AH,09H
MOV DX,OFFSET SCREEN
INT 21H 			 ;print initial message


MOV AH,2CH; 
INT 21H;  ;get time
PUSH DX   ; save it on the stack, to see in the end total time
PUSH CX

MOV AL,DH  ;DH -seconds , CL-minutes, CH- hours
MOV AH,0
MOV CL,3
DIV CL	  ; we choose a board randomly by dividing the current second number to 3 (we have 20 boards corresponding to 60 seconds)  

MOV AH,0	;we dont care about the remainder
LEA BX,BYTE PTR BOARD1   ; we take the adress of the first board
MOV CL,5				
MUL CL					 
ADD BX,AX		         ; and add the random number from 0->19 multiplied with 5 (since we have 5 bits on one board) and get the start
						 ; adress of a random board

MOV BP,0     ;use BP to get the values from the board
NEW_BOARD:
MOV AL,[BX]  ; BX has the begining of the random board
MOV BOARD[BP],AL    ;Board will be the active board on which we play
INC BX
INC BP
CMP BP,5			; we walks through the 5 values of the board
JL NEW_BOARD

REINIT:

BOARDD   ;macro that draws the board

CITIRE:

MOV AX,01
INT 33H ; turn on mouse cursor

MOV AH,01H
INT 16H    ;get state of keyboard buffer
JZ NOTKEY
JMP FIN    ;if a key is pressed, end the game

NOTKEY:

MOV AX,03H   
INT 33H   	;return mouse position and status 
TEST BL,1   ; check BL for left click
JZ CITIRE

  ;if there was a mouseclick, we check if the click is in the correct position
	; DI will hold the column of the board (if the click was correct)
	; SI will hold the row of the board

CMP CX,60
JL CITIRE   

PRIMAC:			;check if the coordinates corespond to the first column, if so make DI=0
CMP CX,100    
JG DOUAC
MOV DI,0
JMP VERL	

DOUAC:
CMP CX,120
JL CITIRE			;if its inbetween columns, jump back to reading the next click
CMP CX,160
JG TREIAC
MOV DI,1
JMP VERL		;if its in a certain column, jump to finding the corespoding line

TREIAC:
CMP CX,180
JL CITIRE
CMP CX,220
JG PATRAC
MOV DI,2
JMP VERL

PATRAC:
CMP CX,240
JL CITIRE
CMP CX,280
JG CINCEAC
MOV DI,3
JMP VERL

CINCEAC:
CMP CX,300
JGE SART
JMP CITIRE

SART:
CMP CX,340
JLE SARI
JMP CITIRE

SARI:
MOV DI,4


VERL:			; check lines, same as columns

CMP DX,30 
JGE PRIMAL
JMP CITIRE		;if its inbetween rows, jump back to reading the next click

PRIMAL:			;check if the coordinates corespond to the first row, if so make SI=0
CMP DX,50
JG DOUAL
MOV SI,0
JMP CLICKBUN	;if its in a certain row, then it is a corect click, and we will compute the new board

DOUAL:
CMP DX,60
JGE SARA
JMP CITIRE
SARA:
CMP DX,80
JG TREIAL
MOV SI,1
JMP CLICKBUN

TREIAL:
CMP DX,90
JGE SARB
JMP CITIRE
SARB:
CMP DX,110
JG PATRAL
MOV SI,2
JMP CLICKBUN

PATRAL:
CMP DX,120
JGE SARC
JMP CITIRE
SARC:
CMP DX,140
JG CINCEAL
MOV SI,3
JMP CLICKBUN

CINCEAL:
CMP DX,150
JG SARR
JMP CITIRE
SARR:
CMP DX,170
JLE TARE
JMP CITIRE
TARE:
MOV SI,4

CLICKBUN:			; a correct click was registered, for which we have a column and a row (DI and SI)

INC MOVES  ;count the correct move

MOV AL,FYVALUES[DI]   ; FYValues are for the row of the cell that was clicked (we need to change the value of it and its adjacent 2 cells)
MOV AH,YVALUES[DI]    ; YValues is for the other 2 rows, for which we only have to change 1 value

XOR BOARD[SI],AL     ; invert the lights on the clicked position (XOR with 1 acts as an inverter)

CMP SI,4
JE MAX    ;check if we are on the last row (we cant change the one below it if its the last)

CMP SI,0   ;check if we are on the first row (we cant change the one above it if its the first)
JE MIN		

ADD SI,1			; change the value on the row above the clicked cell
XOR BOARD[SI],AH
SUB SI,2		   ; and on the row below
XOR BOARD[SI],AH

JMP VERIF

MIN:
ADD SI,1
XOR BOARD[SI],AH   ;if we are on the first row, we only check the one below
JMP VERIF

MAX:
SUB SI,1  		;if we are on the last row, we only check the one above
XOR BOARD[SI],AH


VERIF:

MOV BP,0FFFFH
MOV SI,0030H
DELAY:
DEC BP
JNZ DELAY
DEC SI
JNZ DELAY  ;implement a short delay , so you cant click multiple times on a square in a short time


MOV CL,0
ADD CL,BOARD[1]
ADD CL,BOARD[2]
ADD CL,BOARD[3]
ADD CL,BOARD[4]
ADD CL,BOARD[0]
CMP CL,0 			; check if the board has only 0s => All lights are off

JE WON				;if so , the user won
JMP REINIT			;otherwise, we redraw the board and wait for the next correct mouse click

WON:

BOARDD 			; we print the empty board, to show the user that he won

MOV AH,09H
MOV DX,OFFSET WIN
INT 21H					; we print the win message

MOV AH,09H
MOV DX,OFFSET RESTART
INT 21H					; and the restart one

MOV COL,201
MOV ROW,201			;set the position where to print the moves
POSITION

MOV PSTRING,OFFSET NRMOVES	;print the moves message
STRING

MOV AX,MOVES
WRITE			;print the moves

MOV AX,0
MOV MOVES,AX  ;reset moves

MOV COL,120		;set the position where to print the seonds
MOV ROW,90
POSITION
 
MOV PSTRING,OFFSET SECONDS ;print the seconds message
STRING

 
MOV AH,2CH;
INT 21H;   ;get current time 

POP BX
POP AX  ; pop the initial time values saved on the stack

CMP DH,AH		;we adjust the seconds, so they cant be negative
JGE GSECS

ADD DH,60  ;adding 60 and substracting 1 minute if neede
DEC CL

GSECS:

CMP CL,BL  ; we do the same adjustment for the minutes
JGE GMINS

ADD CL,60
DEC CH

GMINS:
SUB DH,AH  ; we substract the number of current seconds (adjusted) with the initial second timer
MOV AL,DH
MOV AH,0
WRITE	; and we print it out


INC ROW		;we position ourselves on the next row
POSITION

MOV PSTRING,OFFSET MINUTES 	;and we print the minutes string
STRING

SUB CL,BL	; we substract the number of current minutes (adjusted) with the initial minute timer
MOV AL,CL
MOV AH,0
WRITE		;and then the actual value of the minutes

INC ROW  ; we position on the next row
POSITION

MOV PSTRING,OFFSET HOURS  ;print the hours string
STRING


SUB CH,BH	; we do the same substraction for hours
MOV AL,CH
MOV AH,0
WRITE    ; and print the actual number of hours (needed to finish)


WAITK:			;ending screen, waiting for a key to be pressed 
MOV AH,00H
INT 16H		;read key press

CMP AH,28  ; if its not ENTER, end the program 	
JNE FIN
JMP RESTART_GAME   ;otherwise start a new round

FIN:  ;end game

MOV AX,0
INT 10H	       ;clear the screen

MOV AH,04CH
INT 21H			;end the program

MAIN ENDP
CODE ENDS
END MAIN