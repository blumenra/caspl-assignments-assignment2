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

STACK_CAPACITY: equ 5

section .rodata
    str: DB "Hello World", 0
    format_str: DB "%s", 10, 0
    format_int: DD "%d"
    error_overflow: DB "Error: Operand Stack Overflow", 0
    error_insufficient: DB "Error: Insufficient Number of Arguments on Stack", 0
    error_expTooLarge: DB "Error: exponent too large", 0


section .bss
    input: resb 80
    stack: resb 4*STACK_CAPACITY


section .data
    stack_counter: DD 0


section .text 
    align 16 
    global main 

main:

    push ebp
    mov ebp, esp
    
    pushad
    pushfd


    call my_calc
    
    popfd
    popad

    mov esp, ebp    ; return esp to its original place in the beginning of main
    pop ebp         ; pop ebp because we pushed it at the beginning of main

    push 0            ; return value of exit
    call exit

    ret


my_calc:
    
    pushad
    pushfd


    push STACK_CAPACITY
    push format_int
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
    push format_str
    call printf
    add esp, 8  
  
    popfd
    popad

    ret