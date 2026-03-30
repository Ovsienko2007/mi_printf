section .data
    buf_size     dw 0
    max_buf_size equ 32
    num_arr      db '0123456789ABCDEF'
    symb db '!'
    

section .bss
    buffer resb 32  ; буфер для копирования строки

section .text
    global _start

buffer_out:
    mov rax, 1          ; write
    mov rdi, 1          ; stdout
    mov rsi, buffer     ; адрес buffer
    movzx rdx, word [buf_size] ; длина buffer
    syscall

    mov word [buf_size], 0 

    ret

print:
    push rax
    push rcx        ; сохраняем rcx!
    push rdi
    push rsi
    push rdx
    
    mov rax, 1
    mov rdi, 1
    mov rsi, symb
    mov rdx, 1
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rcx         ; восстанавливаем rcx
    pop rax
    ret

put_num_in_buf:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    
    mov eax, [rbp+16]           ; eax = num
    mov ebx, [rbp+24]           ; ebx = number format

    cmp ebx, 10
    jne not_dec

    cmp eax, 0
    jge upper_0

    movzx ecx, word [buf_size]
    mov byte [buffer + ecx], '-'      ; записать минус
    inc word [buf_size]               ; увеличить смещение

    neg eax
not_dec:

upper_0:

    xor rcx, rcx                ; ecx = 0

start_split:                    ; split num on symbols
    xor rdx, rdx                ; edx = 0
    div ebx                     ; get current num

    mov edx, [num_arr + edx]    ; change num to ascii code
    push rdx                    ; save num

    inc ecx                     ; ecx++ find num len
    cmp eax, 0                  ; if it end of word
    jne start_split

                                ; check buffer len
    mov ax, max_buf_size        ; max len of occupied buffer's part
    sub ax, cx
    cmp ax, word [buf_size]     ; will fit into the buffer
    ja not_clean
    call  buffer_out            ; clean buf

not_clean:

                                ; put num in buffer
    movzx ebx, word [buf_size]  ; free point in buffer
start_print:
    pop rax                     ; get symbol
    mov [buffer + ebx], al     ; put smb in buffer

    inc ebx                     ; update free point
    loop start_print            ; go to new iteration

    mov word [buf_size], bx      ; update [buffer_size]

    pop rdx
    pop rcx
    pop rbx
    pop rbp

    ret


_start:
    push qword 16
    push qword -11
    call put_num_in_buf
    add rsp, 8
    call buffer_out

    mov eax, 1
    mov ebx, 0
    int 0x80
