extern exit 
extern printf 
extern fprintf 
extern malloc 
extern free
extern fgets 
extern stderr 
extern stdin 
extern stdout 
extern fopen

section .rodata
    str: DB "Hello World", 0
    format: DB "%s", 10, 0
    error_overflow: DB "Error: Operand Stack Overflow", 0
    error_insufficient: DB "Error: Insufficient Number of Arguments on Stack", 0
    error_expTooLarge: DB "Error: exponent too large", 0


section .bss
    input: resb 80


section .text 
    align 16 
    global main 

main: 
  
    call my_calc
    

    push 0            ; return value of exit
    call exit

    ret

my_calc:
    
    pushad
    pushfd


    push str
    push format
    push dword [stdout]          ; send return value from my_calc to fprintf
    call fprintf
    add esp, 12

    ;push str
    ;push format
    ;call printf
    ;add esp, 8

    push dword [stdin]
    push 80
    push input
  
    call fgets
    add esp, 12  
    push input
    push format
    call printf
    add esp, 8  
  
    popfd
    popad

    ret