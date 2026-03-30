section .data
    buf_size     dw 0
    max_buf_size equ 32
    num_arr      db '0123456789ABCDEF'
    symb db '!'
    
; %d print_sign_dec
; %u print_unsign_dec
; %o print_oct
; %b print_bin
; %x print_hex

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

;_____________________________________
; split and put sign number in buffer (notation = 10)
; ENTRY:
;       par = number
; CHANGE: rax, rcx, rbx, rdx
;_____________________________________
print_sign_dec:
    push rbp                    ; save regs
    mov  rbp, rsp                ; save it for params

    mov eax, [rbp+16]           ; number
    mov ebx, 10

    cmp eax, 0
    jge not_need_minus

    movzx ecx, word [buf_size]
    mov byte [buffer + ecx], '-'      ; записать минус
    inc word [buf_size]               ; увеличить смещение

    neg eax
not_need_minus:

    call put_num_in_buf

    pop rbp

    ret

;_____________________________________
; split and put unsign number in buffer (notation = 10)
; ENTRY:
;       par = number
; CHANGE: rax, rcx, rbx, rdx
;_____________________________________
print_unsign_dec:
    push rbp                    ; save regs
    mov  rbp, rsp                ; save it for params

    mov eax, [rbp+16]           ; number //TODO change 16
    mov ebx, 10

    call put_num_in_buf

    pop rbp

    ret

;_____________________________________
; split and put number in buffer (notation = 8)
; ENTRY:
;       par = number
; CHANGE: rax, rcx, rbx, rdx
;_____________________________________
print_oct:
    push rbp                    ; save regs
    mov  rbp, rsp                ; save it for params

    mov eax, [rbp+16]           ; number
    mov ebx, 8

    call put_num_in_buf

    pop rbp

    ret

;_____________________________________
; split and put number in buffer (notation = 2)
; ENTRY:
;       par = number
; CHANGE: rax, rcx, rbx, rdx
;_____________________________________
print_bin:
    push rbp                    ; save regs
    mov  rbp, rsp                ; save it for params

    mov eax, [rbp+16]           ; number
    mov ebx, 2

    call put_num_in_buf

    pop rbp

    ret

;_____________________________________
; split and put number in buffer (notation = 16)
; ENTRY:
;       par = number
; CHANGE: rax, rcx, rbx, rdx
;_____________________________________
print_hex:
    push rbp                    ; save regs
    mov  rbp, rsp                ; save it for params

    mov eax, [rbp+16]           ; number
    mov ebx, 16

    call put_num_in_buf

    pop rbp

    ret

;_____________________________________
; split and put number in buffer
; ENTRY:
;       eax = number
;       ebx = notation
; CHANGE: rax, rcx, rbx, rdx
;_____________________________________
put_num_in_buf:
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
    mov [buffer + ebx], al      ; put smb in buffer

    inc ebx                     ; update free point
    loop start_print            ; go to new iteration

    mov word [buf_size], bx     ; update [buffer_size]

    ret



_start:
    push qword 10
    call print_hex

    add rsp, 8
    call buffer_out

    mov eax, 1
    mov ebx, 0
    int 0x80
