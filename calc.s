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
    str_newlinw: DB  0
    str: DB "Hello World", 0
    format_strln: DB "%s", 10, 0
    format_str: DB "%s", 0
    format_int: DD "%d"
    error_overflow: DB "Error: Operand Stack Overflow", 0
    error_insufficient: DB "Error: Insufficient Number of Arguments on Stack", 0
    error_expTooLarge: DB "Error: exponent too large", 0
    fail_exit_msg: DB "Exiting...", 0
    prompt_arrow: DB ">>calc: ", 0
    print_arrow: DB ">>", 0
    debug_flag: DB "-d", 0
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

    mov esi, dword [ebp+12]         ;save in esi the first arg from the cmd

    cmp dword [esi+4], 0            ;check if there was any agr from cmd
    je cont_main                    ;if not, do not touch the debug variable

    ;compare the cmd arg and the string "-d"
        push dword [esi+4]          ;send as second arg the cmd arg to cmp_str
        push debug_flag             ;send as first arg the string "-d" to cmp_str
        call cmp_str
        add esp, 8
        cmp eax, 0                  ;check the strings were equal
        je cont_main                ;if not, do not touch the debug variable

    mov dword [debug], 1            ;change the debug variable to 1 because the debug falg was sent from cmd

    
    cont_main:
    

    pushad
    pushfd


    call my_calc
    
    ;print the number of successful operations returned from my_calc
        ;////////////////
        push eax
        push format_int
        call printf
        add esp, 8

        push str_newlinw
        push format_strln
        call printf
        add esp, 8
        ;////////////////
    
    popfd
    popad

    mov esp, ebp    ; return esp to its original place in the beginning of main
    pop ebp         ; pop ebp because we pushed it at the beginning of main

    push 0            ; return value of exit
    call exit
    add esp, 4

    ret



my_calc:
    
    push ebp
    mov ebp, esp
    ;****

    ;push STACK_CAPACITY
    ;push format_int
    ;push dword [stdout]            ;send return value from my_calc to fprintf
    ;call fprintf
    ;add esp, 12

    sub esp, 4                      ;allocate space for local variable op_counter
    mov dword [ebp-4], 0            ;counts the successful operations


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
        

        ;debug check of input
            cmp dword [debug], 0
            je end_debug_1
            call debug_print_input
            end_debug_1:
        
        ;debug check of input
            cmp dword [debug], 0
            je end_debug_2
            call debug_print_stack
            end_debug_2:


        ;handle input
            cmp byte [input], 10        ;if the input is empty, start the prompt again and wait for an input
            je prompt
            
            ;clean initial zeros
                call clean_init_zeros

            ;check if "q"
                push sp_q
                call check_special_command
                add esp, 4                      ;restore esp position
                cmp eax, 0
                jne end_my_calc
            

            call check_sp_commands
            cmp eax, 0
            je handle_numeric

            call handle_special_commands ;check if the input is a special command such as 'p', '+' etc.
            cmp eax, 1
            je inc_op_counter

            ;debug
                cmp dword [debug], 0
                je end_debug_3
                call print_stack_size
                end_debug_3:

            jmp prompt


        handle_numeric:
            call handle_numeric_input   ;if it is an numeric input, jump to the label that handles it


            ;cmp eax, 1
            ;debug
                cmp dword [debug], 0
                je end_debug_5
                call print_stack_size
                end_debug_5:
            
            jmp prompt            
        
        inc_op_counter:
            inc dword [ebp-4]

        ;debug
            cmp dword [debug], 0
            je end_debug_6
            call print_stack_size
            end_debug_6:

        jmp prompt                  ;go back to prompt and start over again

    

    end_my_calc:
        mov eax, dword [ebp-4]  ;return op_counter
        add esp, 4              ;clean local variable op_counter

    ;****
    mov esp, ebp
    pop ebp

    ret



add_to_list:
    push ebp
    mov ebp, esp
    ;****

    mov edi, dword [ebp+8]          ;save in edi the LINK to add which was sent as argument
    mov esi, dword [ebp+12]         ;save in edi the LIST to add to which was sent as argument

    mov esi, dword [esi]
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
        mov esi, dword [ebp+12]
        mov dword [esi], edi


    end_for_list:

    ;****
    mov esp, ebp
    pop ebp

    ret    

push_stack:
    push ebp
    mov ebp, esp
    ;****    


    mov eax, 0

    ; check if stack is not full. then start getting the first input (e.g 123456)
        cmp dword [stack_counter], STACK_CAPACITY   ; if the stack is full, print error and return 0 (inside the error label)
        je print_stack_full_error

    mov ebx, dword [stack_counter]              ; save counter inside ebx
    mov ecx, [ebp+8]                            ; save argument to push (address) inside ecx
    mov dword [stack + 4*ebx], ecx              ; save the address at the top of the Stack
    
    inc dword [stack_counter]                   ;inc stack_counter by 1

    mov eax, 1                                  ;the push was a success


    return_push_stack:

    ;****    
    mov esp, ebp
    pop ebp

    ret

pop_stack:
    push ebp
    mov ebp, esp
    ;****
    
    mov eax, 0

    ; check if stack is NOT empty.
        cmp dword [stack_counter], 0    ; if the stack is full, print error and return 0 (inside the error label)
        je print_stack_is_empty_error

    mov ebx, dword [stack_counter]      ;save stack_counter in ebx   
    dec ebx                             ;deb ebx by 1 because it makes sense afterwards

    mov eax, dword [stack+4*ebx]        ;copy the top of the stack into eax as return value
    mov dword [stack+4*ebx], 0          ;remove data from the previous top of the stack

    dec dword [stack_counter]           ;dec stack_counter by 1


    return_pop_stack:

    ;****
    mov esp, ebp
    pop ebp

    ret

handle_numeric_input:
    push ebp
    mov ebp, esp
    ;****

    ;find input length
        mov ecx, 1                      ;use ecx as counter for the length of the input
        loop1:                          ;run over the input until find '\n'
            cmp byte [input+ecx], 10
            je end_loop1
            inc ecx
            jmp loop1

        end_loop1:
            mov dword [input_len], ecx  ;save input length inside input_len


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
                sub dl, 48                      ;dec 48 inorder to convert the char '1' (49 in ascii) to the int 1
                dec ebx
                mov dword [input_counter], ebx
                mov cl, byte [input+ebx]
                sub cl, 48                      ;dec 48 inorder to convert the char '1' (49 in ascii) to the int 1
                jmp continue_for_input

            cl_get_zero:
                mov ebx, dword [input_counter]
                mov dl, byte [input+ebx]
                sub dl, 48                      ;dec 48 inorder to convert the char '1' (49 in ascii) to the int 1
                mov cl, 0
                mov dword [input_counter], ebx

            continue_for_input:
                shl cl, 4                       ;make a nibble out of the byte saved in cl
                or cl, dl                       ;'merge' the two nibbles into one byte (38 => 0x38)
            
            dec ebx
            mov dword [input_counter], ebx

            mov [bcd_num], cl           ;save the converted BCD number (malloc messes up register ecx apparently)


            push 5                      ;push amount of bytes malloc should allocate (1 for data and 4 for address)
            call malloc                 ;return value is saved in reg eax (the address of the new memory space in heap)!
            test eax, eax
            jz   fail_exit
            add esp,4                   ;undo push for malloc

            mov cl, [bcd_num]           ;assign the first byte with the bcd number
            mov byte [eax], cl
            mov dword [eax+1], 0        ;assign the rest 4 bytes with address 0

            push curr_list
            push eax                    ;send the address saved in eax to push_stack as argument
            call add_to_list
            add esp, 8

            jmp for_input

    end_for_input:
    
    ;push the address of the new list to stack
        push dword [curr_list]          ;send the new list which represents the input number to push_stack
        mov dword [curr_list], 0        ;initialize the list for the next input
        call push_stack
        add esp, 4                      ;clean local variable op_counter
    

    ;****
    mov esp, ebp
    pop ebp

    ret

check_sp_commands:
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


    return_check_sp_commands:

    ;****
    mov esp, ebp
    pop ebp

    ret

handle_special_commands:
    push ebp
    mov ebp, esp
    ;****


    push sp_p                       ;send the string "p" as argument to compare with input
    call check_special_command      ;call the function that checks if the input is a sp
    add esp, 4                      ;clean the above push sp
    cmp eax, 0                      ;check if the return value is not null
    jne exec_sp_p    ;if the return value is NOT 0, then eax contains the sp that was sent as an argument so return from the function

    push sp_plus
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne call_exec_sp_plus

    push sp_r
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne call_exec_sp_r

    push sp_l
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne call_exec_sp_l
    
    push sp_d
    call check_special_command
    add esp, 4                      ;restore esp position
    cmp eax, 0
    jne call_exec_sp_d
    
    jmp return_handle_special_commands


    call_exec_sp_d:
        call exec_sp_d
        jmp return_handle_special_commands

    call_exec_sp_plus:
        call exec_sp_plus
        jmp return_handle_special_commands
    
    call_exec_sp_r:
        call exec_sp_r
        jmp return_handle_special_commands

    call_exec_sp_l:
        call exec_sp_l
        jmp return_handle_special_commands



    return_handle_special_commands:
    ;****
    mov esp, ebp
    pop ebp

    ret

exec_sp_p:
    
    call pop_stack
    cmp eax, 0                      ;if the pop failed, it returns 0. else the poped value. else eax holds the poped list
    je return_handle_special_commands     ;if pop failed, go to the label that prints the error that the stack is empty and return 0 in eax

    push eax                        ;send the return value from pop_stack (which is saved in eax) to print
    call print_num
    add esp, 4                      ;clean push of print_num

    mov eax, 1                      ;change return value of handle_special_commands to true

    jmp return_handle_special_commands

exec_sp_d:
    push ebp
    mov ebp, esp
    ;****

    
    call pop_stack
    cmp eax, 0                      ;if the pop failed, it returns 0. else the poped value. else eax holds the poped list
    je return_sp_d                  ;if pop failed, go to the label that prints the error that the stack is empty and return 0 in eax

    ;----
    ;call print_for_myself
    ;----

    sub esp, 4                      ;allocate space on x86 stack for the POPED list (dword [ebp-4])
    sub esp, 4                      ;allocate space on x86 stack for the DUPLICATING list (dword [ebp-8])

    mov dword [ebp-4], eax          ;assign as local variable the poped list
    mov edi, dword [ebp-4]          ;make edi point on the first link if the poped list

    ;make esi point on the empty list which located in ebp-8. it will be the duplicated lisk at the end
        mov esi, ebp
        sub esi, 8
        mov dword [esi], 0                  ;initialize the new list with NULL
        
    ;duplicate poped list
        loop_dup_list:
            cmp edi, 0
            je end_loop_dup_list

            ;create new link
                push edi                    ;backup edi cbecause it might change during add_to_list
                push esi                    ;backup esi cbecause it might change during add_to_list

                push 5                      ;push amount of bytes malloc should allocate (1 for data and 4 for address)
                call malloc                 ;return value is saved in reg eax (the address of the new memory space in heap)!
                test eax, eax
                jz   fail_exit
                add esp,4                   ;undo push for malloc

                pop esi                     ;restore esi to what it was before calling add_to_list
                pop edi                     ;restore edi to what it was before calling add_to_list

            ; copy the data from the current link
                mov bl, byte [edi]
                mov byte [eax], bl
            
            mov byte [eax+1], 0         ;assign the new links''s next to NULL

            push edi                    ;backup edi cbecause it might change during add_to_list
            push esi                    ;backup esi cbecause it might change during add_to_list

            push esi                    ;push the LIST to add to which is located inside the x86 stack
            push eax                    ;push thr LINK to add
            call add_to_list
            add esp, 8                  ;undo pushes for add_to_list
            
            pop esi                     ;restore esi to what it was before calling add_to_list
            pop edi                     ;restore edi to what it was before calling add_to_list

            mov edi, dword [edi+1]
            jmp loop_dup_list

        end_loop_dup_list:

    ;push the original list that was duplicated back to the stack
        push dword [ebp-4]
        call push_stack
        add esp, 4                      ;undo pushes for push_stack
        cmp eax, 0
        ;je free_list

    ;push the DUPLICATED list to stack
        push dword [ebp-8]
        call push_stack
        add esp, 4                      ;undo pushes for push_stack
        cmp eax, 0
        ;je free_list

    add esp, 4                      ;clean local variable DUPLICATED list
    add esp, 4                      ;clean local variable POPED list

    return_sp_d:

    ;****
    mov esp, ebp
    pop ebp

    ret

exec_sp_plus:
    push ebp
    mov ebp, esp
    ;****

    sub esp, 4                  ;allocate space for local variable which will hold the FIRST argument of the addition in [ebp-4]
    sub esp, 4                  ;allocate space for local variable which will hold the SECOND argument of the addition in [ebp-8]
    
    call pop_stack
    cmp eax, 0                  ;if the pop failed, it returns 0. else the poped value. else eax holds the poped list
    je return_sp_plus           ;if pop failed, go to the label that prints the error that the stack is empty and return 0 in eax

    mov dword [ebp-4], eax      ;assign the FIRST poped arg in [ebp-4]
    
    call pop_stack
    cmp eax, 0                  ;if the pop failed, it returns 0. else the poped value. else eax holds the poped list
    je restore_stack_sp_plus    ;if pop failed, go to the label that prints the error that the stack is empty and return 0 in eax

    mov dword [ebp-8], eax      ;assign the SECOND poped arg in [ebp-8]


    push dword [ebp-8]          ;send the SECOND poped argument to the function
    push dword [ebp-4]          ;send the first poped argument to the function
    call add
    add esp, 8                  ;undo pushes for the above function

    push eax
    call push_stack
    add esp, 4
    jmp return_sp_plus


    restore_stack_sp_plus:
        push dword [ebp-4]      ;send the first poped argument to the stack
        call push_stack
        add esp, 4              ;undo push for the above function
        mov eax, 0              ;assign FALSE in the return value
        jmp return_sp_plus


    return_sp_plus:
    add esp, 8                  ;clean two local variables
    ;****
    mov esp, ebp
    pop ebp

    ret

exec_sp_l:
    push ebp
    mov ebp, esp
    ;****

    sub esp, 4                  ;allocate space for local variable which will hold k
    sub esp, 4                  ;allocate space for local variable which will hold n

    
    call pop_stack
    cmp eax, 0                  ;if the pop failed, it returns 0. else the poped value. else eax holds the poped list
    je return_sp_l           ;if pop failed, go to the label that prints the error that the stack is empty and return 0 in eax

    mov dword [ebp-4], eax      ;assign the FIRST poped arg in [ebp-4]
    
    call pop_stack
    cmp eax, 0                  ;if the pop failed, it returns 0. else the poped value. else eax holds the poped list
    je restore_stack_sp_l    ;if pop failed, go to the label that prints the error that the stack is empty and return 0 in eax

    mov dword [ebp-8], eax      ;assign the SECOND poped arg in [ebp-8]


    push dword [ebp-8]          ;send the SECOND poped argument to the function
    push dword [ebp-4]          ;send the first poped argument to the function
    call shift_l
    add esp, 8                  ;undo pushes for the above function
    cmp eax, 0
    je print_exp_too_large_error

    push eax
    call push_stack
    add esp, 4
    jmp return_sp_l


    restore_stack_sp_l:
        push dword [ebp-8]      ;send the second poped argument to the stack
        call push_stack
        add esp, 4              ;undo push for the above function
        
        push dword [ebp-4]      ;send the first poped argument to the stack
        call push_stack
        add esp, 4              ;undo push for the above function
        
        mov eax, 0              ;assign FALSE in the return value
        jmp return_sp_l


    return_sp_l:
    add esp, 8                  ;clean two local variables
    ;****
    mov esp, ebp
    pop ebp

    ret

shift_l:
    push ebp
    mov ebp, esp
    ;****

    ;[ebp+8] is k
    ;[ebp+12] is n


    sub esp, 4                  ;allocate space for local variable which will hold the int k value
    sub esp, 4                  ;allocate space for local variable which will hold the result of the shift left

    ;check if exp is not too large
    bla3:
        mov eax, 0
        mov ebx, dword [ebp+8]
        cmp dword [ebx+1], 0
        jne return_shift_l

    mov dword [ebp-4], 0        ;initialize the space which will hold the int k with 0
    mov eax, dword [ebp+12]     ;initialize the return result list with 0
    mov dword [ebp-8], eax      ;initialize the return result list with 0
    

    ;convert k from BCD to int
        mov esi, dword [ebp+8]  ;put in esi the list which represents k in BCD
        mov ecx, 0
        mov edx, 0
        mov cl, byte [esi]
        mov dl, byte [esi]

        ;convert the LEFT nibble to int
            shr cl, 4
    
        ;convert the RIGHT nibble to int
            shl dl, 4
            shr dl, 4

        ;merge to above two into a proper integer
            mov eax, 0          ;initialize the mulitipicand with 0
            mov ebx, 0          ;initialize the multoplier with 0
            mov al, cl          ;put in al the mulitipicand
            mov bl, 10          ;multoplier
            mul bl              ;al*10
            add ax, dx

        ;**careful! maybe should be just ax
        mov dword [ebp-4], eax


    ;start multiplying n by 2 k times

        mov ecx, 0

        loop_multiply_by_2:
            cmp ecx, dword [ebp-4]  ;check if ecx < k
            je end_loop_multiply_by_2

            push ecx                ;backup counter

            push dword [ebp-8]
            push dword [ebp-8]
            call add
            add esp, 8

            pop ecx                 ;restore counter
            
            mov dword [ebp-8], eax
            inc ecx

            jmp loop_multiply_by_2


    end_loop_multiply_by_2:
        mov eax, dword [ebp-8]

    return_shift_l:

    ;****
    add esp, 8                      ;clean local variables
    mov esp, ebp
    pop ebp

    ret

exec_sp_r:

add:
    push ebp
    mov ebp, esp
    ;****

    sub esp, 4                  ;allocate space for local variable which will hold the result of the addition in [ebp-4]
    sub esp, 4                  ;allocate space for cflag of the last addition

    ;assign in [ebp-4] the next link of curr link of list 1
        mov esi, dword [ebp+8]      ;assign in esi list 1 (first link of curr)

    ;assign in [ebp-8] the next link of curr link of list 2
        mov edi, dword [ebp+12]     ;assign in edi list 2 (first link of curr)

    ;initialize the return result list with 0
        mov dword [ebp-4], 0

    ;initialize the cflag of the last addition with 0
        mov dword [ebp-8], 0


    loop_lists_addition:
        mov eax, 0
        cmp esi, 0
        je esi_link_got_to_end          ;if esi got to the end of list 1, go handle edi
        cmp edi, 0
        je edi_link_got_to_end

        ;both esi and edi DIDNT get to the end of their lists
            mov al, byte [esi]          ;save the data of the link esi is poiting at
            mov bl, byte [edi]
            jmp conv_right_nibbles_if_sum_greater_than_15


        esi_link_got_to_end:
            cmp edi, 0
            je check_for_last_cflag     ;if also edi got to end of list 2, go check if there was a carry along the calculation
            mov bl, byte [edi]
            jmp conv_right_nibbles_if_sum_greater_than_15


        edi_link_got_to_end:
            cmp esi, 0
            je check_for_last_cflag     ;if also esi got to end of list 2, go check if there was a carry along the calculation
            mov bl, byte [esi]
            jmp conv_right_nibbles_if_sum_greater_than_15
        
        conv_right_nibbles_if_sum_greater_than_15:
            mov ecx, 0                  ;initialize cl for coming use
            mov edx, 0                  ;initialize dl for coming use
            mov cl, al                  ;copy al to cl
            mov dl, bl                  ;copy al to dl

            ;leave only the right nibbles of the two byte
                shl cl, 4
                shr cl, 4
                
                shl dl, 4
                shr dl, 4

            add cl, dl
            cmp cl, 00010000b
            jl conv_left_nibbles_if_sum_greater_than_15                   ;if the sum of the both right nibbles are LESS than 16, do nothing!

            sub cl, 00001010b           ;sub 10 from the previous sum

            ;leave only the left nibble of al, with adding carry of 1 to it
                shr al, 4
                add al, 1
                shl al, 4

            ;restore al to be the new converted al
                or al, cl

            ;leave only the left nibble of bl
                shr bl, 4
                shl bl, 4

        conv_left_nibbles_if_sum_greater_than_15:
            mov ecx, 0                  ;initialize cl for coming use
            mov edx, 0                  ;initialize dl for coming use
            mov cl, al                  ;copy al to cl
            mov dl, bl                  ;copy al to dl

            ;leave only the left nibbles of the two byte
                shr cl, 4
                
                shr dl, 4

                add cl, dl
                cmp cl, 00010000b
                jl do_daa                   ;if the sum of the both right nibbles are LESS than 16, do nothing!

                sub cl, 00001010b           ;sub 10 from the previous sum
                shl cl, 4

            ;leave only the right nibble of al, with adding carry of 1 to it
                shl al, 4
                mov dword [ebp-8], 1          ;put in our cflag 1 if cflag was set
                shr al, 4

            ;restore al to be the new converted al
                or al, cl

            ;leave only the left nibble of bl
                mov bl, 0

            jmp do_daa2

        do_daa:
            mov dword [ebp-8], 0              ;initialize our cflag with 0
            add eax, dword [ebp-8]            ;add the carry (if there was any) from last addition
        
        do_daa2:
            add al, bl
            daa

            jnb cont
                mov dword [ebp-8], 1          ;put in our cflag 1 if cflag was set
        cont:
            ;create a new link
                mov ebx, 0                  ;initialize ebx with 0
                mov bl, al                 ;save the value of the result from all above in bl (becasue malloc is going to change the value of eax)

                push ebx                    ;backup ebx because it might change during malloc
                push edi                    ;backup edi because it might change during malloc
                push esi                    ;backup esi because it might change during malloc

                push 5                      ;push amount of bytes malloc should allocate (1 for data and 4 for address)
                call malloc                 ;return value is saved in reg eax (the address of the new memory space in heap)!
                test eax, eax
                jz   fail_exit
                add esp,4                   ;undo push for malloc

                pop esi                     ;restore esi to what it was before calling malloc
                pop edi                     ;restore edi to what it was before calling malloc
                pop ebx                     ;restore ebx to what it was before calling malloc

            ;initialize the new link
                mov byte [eax], bl
                mov byte [eax+1], 0

            ;add the new link to the result link
                push edi                    ;backup edi cbecause it might change during add_to_list
                push esi                    ;backup esi cbecause it might change during add_to_list

                mov ecx, ebp
                sub ecx, 4
                push ecx                 ;push the LIST to add to which is located inside the x86 stack
                push eax                    ;push thr LINK to add
                call add_to_list
                add esp, 8                  ;undo pushes for add_to_list
                
                pop esi                     ;restore esi to what it was before calling add_to_list
                pop edi                     ;restore edi to what it was before calling add_to_list

            cmp esi, 0
            je continue
            mov esi, dword [esi+1]          ;advance the curr link of list 1 by 1
            
            continue:
                cmp edi, 0
                je loop_lists_addition
                mov edi, dword [edi+1]          ;advance the curr link of list 2 by 1
        
        jmp loop_lists_addition

    check_for_last_cflag:
        ;if on the last two links the cflag was up- we need to create a new link with 1
            cmp dword [ebp-8], 0
            je return_add


        ;create a new link
            push ebx                    ;backup ebx because it might change during malloc
            push edi                    ;backup edi because it might change during malloc
            push esi                    ;backup esi because it might change during malloc

            push 5                      ;push amount of bytes malloc should allocate (1 for data and 4 for address)
            call malloc                 ;return value is saved in reg eax (the address of the new memory space in heap)!
            test eax, eax
            jz   fail_exit
            add esp,4                   ;undo push for malloc

            pop esi                     ;restore esi to what it was before calling malloc
            pop edi                     ;restore edi to what it was before calling malloc
            pop ebx                     ;restore ebx to what it was before calling malloc

        ;initialize the new link with data=1, next=NULL
            mov byte [eax], 1
            mov byte [eax+1], 0

        ;add the new link to the result link
            push edi                    ;backup edi cbecause it might change during add_to_list
            push esi                    ;backup esi cbecause it might change during add_to_list

            mov ecx, ebp
            sub ecx, 4
            push ecx                 ;push the LIST to add to which is located inside the x86 stack
            push eax                    ;push thr LINK to add
            call add_to_list
            add esp, 8                  ;undo pushes for add_to_list
            
            pop esi                     ;restore esi to what it was before calling add_to_list
            pop edi                     ;restore edi to what it was before calling add_to_list


    return_add:
    mov eax, dword [ebp-4]
    add esp, 4                         ;clean local valiables
    ;****
    mov esp, ebp
    pop ebp

    ret

print_num:
    push ebp
    mov ebp, esp
    ;****

    mov esi, dword [ebp+8]  ;save the list sent as argument inside esi
    
    
    ;print prompt arrow
        ;////////////////
            push print_arrow
            push format_str
            call printf
            add esp, 8
        ;////////////////
    
    cmp esi, 0
    jne print_num_for

    mov eax, 0
    jmp return_print_num

    print_num_for:
        cmp dword [esi+1], 0             ;check if it is the end of the list
        je end_print_num_for

        mov eax, 0                      ;initialize eax with 0
        mov ebx, 0                      ;initialize ebx with 0
        mov al, [esi]                   ;save the data from the current link inside al (1 byte)
        mov bl, al                      ;copy the above data into bl

        ;convert the RIGHT nibble back to byte
            shl bl, 4
            shr bl, 4
        
        ;convert the LEFT nibble back to byte
            shr al, 4

        sub esp, 4                      ;allocate space fot the LEFT digit of the current pair
        mov dword [esp], ebx            ;save the digit in the space allocated above
        
        sub esp, 4                      ;allocate space fot the RIGHT digit of the current pair
        mov dword [esp], eax            ;save the digit in the space allocated above

        mov esi, dword [esi+1]          ;move to the next link in list
        jmp print_num_for               ;loop until we get to the end of the list


    end_print_num_for:
    ;in case of lisk of a SINGLE link (the code is almost same as above)
        
        mov eax, 0
        mov ebx, 0
        mov al, byte [esi]              ;save the current digit in eax
        mov bl, al

        shl bl, 4
        shr bl, 4
        
        shr al, 4


        sub esp, 4                      ;allocate space for the sigle digit
        mov dword [esp], ebx            ;save the converted digit back in the stack

        cmp al, 0                       ;if cl is 0, dont allocate space for another digit
        je while_esp_lower_than_ebp
        
        sub esp, 4                      ;allocate space for the sigle digit
        mov dword [esp], eax            ;save the converted digit back in the stack


    ;loop over the digits in x86 stack and print digit by digit
    while_esp_lower_than_ebp:
        
        cmp esp, ebp                    ;loop until esp reaches ebp back
        je return_print_num

        ;print the current digit
            ;////////////////
            push dword [esp]
            push format_int
            call printf
            add esp, 8
            ;////////////////

        add esp, 4                      ;clean memory of the printed digit
        jmp while_esp_lower_than_ebp    ;loop until esp reaches ebp back




    return_print_num:
    
    ;print newline
        ;////////////////
        push str_newlinw
        push format_strln
        call printf
        add esp, 8
        ;////////////////

    ;****
    ;add esp, 1
    mov esp, ebp
    pop ebp

    ret

print_stack:
    push ebp
    mov ebp, esp
    ;****

    mov ecx, 0
    
    loop_print_stack:
        mov edx, dword [stack_counter]
        cmp ecx, edx
        je return_print_stack

        push ecx
        push dword [stack+4*ecx]
        call print_num
        add esp, 4
        pop ecx

        inc ecx

    jmp loop_print_stack
    
    return_print_stack:
    ;****
    mov esp, ebp
    pop ebp

    ret

check_special_command:
    push ebp
    mov ebp, esp
    ;****
    
    push input
    push dword [ebp+8]
    call cmp_str
    add esp, 8

    ;****
    mov esp, ebp
    pop ebp

    ret

cmp_str:
    push ebp
    mov ebp, esp
    ;****

    mov eax, 0                          ;initialize return value with 0
    mov esi, dword [ebp+8]              ; put in esi the argument (sp command address)
    mov edi, dword [ebp+12]
    mov ecx, 0                          ;define ecx as index for the loop

    for_:
        cmp byte [esi+ecx], 0
        je final_check_1
        mov bl, byte [esi+ecx]
        cmp byte [edi+ecx], bl
        jne not_sp
        inc ecx
        jmp for_


    final_check_1:
        cmp byte [edi+ecx], 10
        je is_sp
        jmp final_check_2

    final_check_2:
        cmp byte [edi+ecx], 0
        je is_sp
        jmp not_sp

    is_sp:
        mov eax, esi
        jmp end_for_

    not_sp:
        mov eax, 0

    end_for_:


    ;****
    mov esp, ebp
    pop ebp

    ret

clean_input_buffer:
    push ebp
    mov ebp, esp
    ;****

    mov esi, input

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

clean_init_zeros:
    push ebp
    mov ebp, esp
    ;****

    mov ecx, 0                      ;use ecx as index for the input buffer
    mov ebx, 0                      ;use ebx as index for the buffer we copy to

    loop_clean_zeros:
        cmp byte [input+ecx], '0'      ;check if the current digit is zero
        jne end_loop_clean_zeros
        inc ecx
        jmp loop_clean_zeros


    end_loop_clean_zeros:

    cmp byte [input+ecx], 10         ;check if the current digit is newline
    je change_input_to_zero
    section .bss
        buf: resb 80
    section .text

    loop_copy_to_new_buffer:
        cmp byte [input+ecx], 10      ;check if the current digit is newline
        je copy_back_to_input
        mov al, byte [input+ecx]
        mov byte [buf+ebx], al
        inc ecx
        inc ebx
        jmp loop_copy_to_new_buffer  


    copy_back_to_input:
    
    mov al, byte [input+ecx]
    mov byte [buf+ebx], al
    
    call clean_input_buffer
    mov ebx, 0
    mov ecx, 0

    loop_copy_back_to_input:
        cmp byte [buf+ebx], 10      ;check if the current digit is newline
        je end_loop_copy_back_to_input
        mov al, byte [buf+ebx]
        mov byte [input+ecx], al
        inc ecx
        inc ebx
        jmp loop_copy_back_to_input

    end_loop_copy_back_to_input:
    
        mov al, byte [buf+ebx]
        mov byte [input+ecx], al
        jmp return_clean_init_zeros


    change_input_to_zero:
        call clean_input_buffer
        mov byte [input], '0'
        mov byte [input+1], 10


    return_clean_init_zeros:

    ;****
    mov esp, ebp
    pop ebp

    ret

print_stack_is_empty_error:

    pushad
    pushfd
    
    push error_insufficient
    push format_strln
    call printf
    add esp, 8

    popfd
    popad
    
    mov eax, 0
    jmp return_pop_stack

print_stack_full_error:
    pushad
    pushfd

    push error_overflow
    push format_strln
    call printf
    add esp, 8
    
    popfd
    popad

    mov eax, 0


    jmp return_push_stack

print_exp_too_large_error:

    pushad
    pushfd
    
    push error_expTooLarge
    push format_strln
    call printf
    add esp, 8

    popfd
    popad
    
    mov eax, 0
    jmp restore_stack_sp_l

func_format:
    push ebp
    mov ebp, esp
    ;****


    ;<func code>
    ;mov eax, <return value>
    

    ;****
    mov esp, ebp
    pop ebp

    ret

print_for_myself:
    pushad
    pushfd
    push ebp
    mov ebp, esp
    ;****

    ;////////////////
    push str
    push format_strln
    call printf
    add esp, 8
    ;////////////////

    ;****
    mov esp, ebp
    pop ebp
    popfd
    popad

    ret

fail_exit:
    push fail_exit_msg
    push format_strln
    call printf
    add esp, 8

    push 0
    call exit

debug_print_input:
    pushad
    pushfd
    push ebp
    mov ebp, esp
    ;****

    section .data
        debug_input_msg: DB "You entered %s", 0

    section .text
        ;*print "You entered %s"
        push print_arrow
        push format_str
        push dword [stderr]
        call fprintf
        add esp, 12

        push input
        push debug_input_msg
        push dword [stderr]
        call fprintf
        add esp, 12
        ;*

    ;****
    mov esp, ebp
    pop ebp
    popfd
    popad

    ret

debug_print_stack:
    pushad
    pushfd
    push ebp
    mov ebp, esp
    ;****

    section .data
        debug_print_stack_msg: DB "Stack:", 10 , 0

    section .text
    ;*print "Stack:"
        push input
        push debug_print_stack_msg
        push dword [stderr]
        call fprintf
        add esp, 12

        call print_stack
    ;*

    ;****
    mov esp, ebp
    pop ebp
    popfd
    popad

    ret

print_stack_size:
    pushad
    pushfd
    push ebp
    mov ebp, esp
    ;****
    
    section .data
        debug_stack_size_msg: DB "Stack size is %d", 10, 0
    
    section .text
        ;*print "Stack size is %d"
        push print_arrow
        push format_str
        push dword [stderr]
        call fprintf
        add esp, 12

        push dword [stack_counter]
        push debug_stack_size_msg
        push dword [stderr]
        call fprintf
        add esp, 12
        ;*
    
    ;****
    mov esp, ebp
    pop ebp
    popfd
    popad

    ret

debug_print_format:
    ;**************
    ;debug check of input
        ;cmp dword [debug], 1
        ;jne end_debug_1

        ;section .data
            ;debug_input_msg: DB "You entered %s", 0
            ;debug_stack_size_msg: DB "Stack size is %d", 10, 0

        ;section .text
        
            ;*print "You entered %s"
            ;push print_arrow
            ;push format_str
            ;push dword [stderr]
            ;call fprintf
            ;add esp, 12

            ;push input
            ;push debug_input_msg
            ;push dword [stderr]
            ;call fprintf
            ;add esp, 12
            ;*

            ;*print "Stack size is %d"
            ;push print_arrow
            ;push format_str
            ;push dword [stderr]
            ;call fprintf
            ;add esp, 12

            ;push dword [stack_counter]
            ;push debug_stack_size_msg
            ;push dword [stderr]
            ;call fprintf
            ;add esp, 12
            ;*

        ;end_debug_1:
    ;**************

