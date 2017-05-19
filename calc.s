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
    format_strln: DB "%s", 10, 0
    format_str: DB "%s", 0
    format_int: DD "%d"
    error_overflow: DB "Error: Operand Stack Overflow", 0
    error_insufficient: DB "Error: Insufficient Number of Arguments on Stack", 0
    error_expTooLarge: DB "Error: exponent too large", 0
    fail_exit_msg: DB "Exiting...", 0
    prompt_arrow: DB ">>calc: ", 0
    sp_p: DB "p", 0
    sp_plus: DB "+", 0
    sp_r: DB "r", 0
    sp_l: DB "l", 0
    sp_d: DB "d", 0
    sp_q: DB "q", 0


section .bss
    input: resb 80
    stack: resb 4*STACK_CAPACITY
    bcd_num: resb 1


section .data
    input_len: DD 0
    input_counter: DD 0
    stack_counter: DD 0
    debug: DD 0
    curr_list: DD 0


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
    add esp, 4

    ret


my_calc:
    
    pushad
    pushfd
    push ebp
    mov ebp, esp
    ;****

    ;push STACK_CAPACITY
    ;push format_int
    ;push dword [stdout]          ; send return value from my_calc to fprintf
    ;call fprintf
    ;add esp, 12

    prompt:
        push prompt_arrow
        push format_str
        call printf
        add esp, 8

        ;clean input buffer
            call clean_input_buffer

        ; wait for input from user
            push dword [stdin]
            push 80
            push input
            call fgets
            add esp, 12  
        

        ;handle input
            cmp byte [input], 10        ;if the input is empty, start the prompt again and wait for an input
            je prompt



            call check_special_commands  ;check if the input is a special command such as 'p', '+' etc.
            cmp eax, 0
            jne handle_special_command


        ;handle numeric input
            ; check if stack is not full. then start getting the first input (e.g 123456)
                
                cmp dword [stack_counter], STACK_CAPACITY   ; if the stack is full, return without doing anything (eax = 0)
                je print_stack_full_error

            ;find input length
                mov ecx, 1                      ;use ecx as counter for the length of the input
                loop1:
                    cmp byte [input+ecx], 10
                    je end_loop1
                    inc ecx
                    jmp loop1

                end_loop1:
                    mov dword [input_len], ecx


            ;start linking pairs from input
            mov ebx, dword [input_len]
            dec ebx
            mov dword [input_counter], ebx



            for_input:

                mov ecx, 0
                mov edx, 0

                cmp dword [input_counter], 0
                jl end_for_input

                


                cmp dword [input_counter], 0
                je cl_get_zero

                ; convert to BCD: 01110000 (7) OR 00000011 (3) => 01110011 (0x73)
                ; the following method assumes input correctness (meaning, only numbers and special commands)!!
                    mov ebx, dword [input_counter]
                    mov dl, byte [input+ebx]
                    dec ebx
                    mov dword [input_counter], ebx
                    mov cl, byte [input+ebx]
                    jmp continue_for_input

                cl_get_zero:
                    mov ebx, dword [input_counter]
                    mov dl, byte [input+ebx]
                    mov cl, 0
                    mov dword [input_counter], ebx

                continue_for_input:
                    shl cl, 4
                    or cl, dl
                
                dec ebx
                mov dword [input_counter], ebx

                mov [bcd_num], cl           ;save the converted BCD number (malloc messes up register ecx apparently)


                ;////////////////
                ;mov eax, 0
                ;mov al, bcd_num
                ;push bcd_num
                ;push format_strln
                ;call printf
                ;add esp, 8
                ;////////////////


                push 5                      ;push amount of bytes malloc should allocate (1 for data and 4 for address)
                call malloc                 ;return value is saved in reg eax (the address of the new memory space in heap)!
                test eax, eax
                jz   fail_exit
                add esp,4                   ;undo push for malloc
         
                mov cl, [bcd_num]           ;assign the first byte with the bcd number
                mov byte [eax], cl
                mov dword [eax+1], 0        ;assign the rest 4 bytes with address 0

                push eax                    ;send the address saved in eax to push_stack as argument
                call add_to_curr_list
                add esp, 4

                jmp for_input

            end_for_input:
                
                push dword [curr_list]
                call push_stack
                add esp, 4

            jmp prompt

        mov esi, [stack]
        ;mov edx, 0
        mov esi, dword [esi+1]
        push esi
        push format_strln
        call printf
        add esp, 8

    ;****
    mov esp, ebp
    pop ebp
    popfd
    popad

    ret


add_to_curr_list:
    push ebp
    mov ebp, esp
    ;****

    mov edi, [ebp+8]
    mov esi, dword [curr_list]

    cmp esi, 0
    je add_first_link

    for_list:
        cmp dword [esi+1], 0
        je add_link
        mov esi, dword [esi+1]
        jmp for_list


    add_link:
        mov dword [esi+1], edi
        jmp end_for_list

    add_first_link:
        mov dword [curr_list], edi


    end_for_list:

    ;****
    mov esp, ebp
    pop ebp

    ret    


push_stack:
    push ebp
    mov ebp, esp
    ;****    


    mov ebx, dword [stack_counter]              ; save counter inside ebx
    mov ecx, [ebp+8]                            ; save argument to push (address) inside ecx
    mov dword [stack + 4*ebx], ecx              ; save the address at the top of the Stack
    inc ebx                                     ; increase the stack counter by 1
    mov dword [stack_counter], ebx


    ;****    
    mov esp, ebp
    pop ebp

    ret


handle_special_command:
    push str
    push format_strln
    call printf
    add esp, 8
    jmp fail_exit

check_special_commands:
    push ebp
    mov ebp, esp
    ;****


    push sp_p                       ;send the string "p" as argument to compare with input
    call check_special_command      ;call the function that checks if the input is a sp
    add esp, 4                      ;restore esp position
    cmp eax, 0                      ;check if the return value is not null
    jne return_check_sp_commands    ;if the return value is NOT 0, then eax contains the sp that was sent as an argument so return from the function

    push sp_plus
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne return_check_sp_commands

    push sp_r
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne return_check_sp_commands

    push sp_l
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne return_check_sp_commands
    
    push sp_d
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne return_check_sp_commands

    push sp_q
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne return_check_sp_commands


    return_check_sp_commands:
    ;****
    mov esp, ebp
    pop ebp

    ret


check_special_command:
    push ebp
    mov ebp, esp
    ;****

    mov eax, 0                          ;initialize return value with 0
    mov esi, dword [ebp+8]              ; put in esi the argument (sp command address)

    mov ecx, 0                          ;define ecx as index for the loop

    for_:
        cmp byte [esi+ecx], 0
        je final_check
        mov bl, byte [esi+ecx]
        cmp byte [input+ecx], bl
        jne not_sp
        inc ecx
        jmp for_


    final_check:
        cmp byte [input+ecx], 10
        je is_sp
        jmp not_sp

    is_sp:
        mov eax, esi
        jmp end_for_

    not_sp:
        mov eax, 0

    end_for_:

    ;<func code>
    ;mov eax, <return value>
    

    ;****
    mov esp, ebp
    pop ebp

    ret

clean_input_buffer:
    push ebp
    mov ebp, esp
    ;****

    mov esi, [ebp+8]

    clean_input_for:
        cmp byte [esi], 0
        je finished_cleaning
        mov byte [esi], 0
        inc esi
        jmp clean_input_for

    finished_cleaning:

    ;****
    mov esp, ebp
    pop ebp

    ret


print_stack_full_error:
    push error_overflow
    push format_strln
    call printf
    add esp, 8

    jmp fail_exit



func_format:
    pushad
    pushfd
    push ebp
    mov ebp, esp
    ;****


    ;<func code>
    ;mov eax, <return value>
    

    ;****
    mov esp, ebp
    pop ebp
    popfd
    popad

    ret


print_for_myself:
    ;////////////////
    push str
    push format_strln
    call printf
    add esp, 8
    ;////////////////


fail_exit:
    push fail_exit_msg
    push format_strln
    call printf
    add esp, 8

    push 0
    call exit