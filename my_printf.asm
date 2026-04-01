section .data
    buf_size     dw 0
    smb          db 10
    max_buf_size equ 32
    num_arr      db '0123456789ABCDEF'
    string       db '! %s %s%d', 10, 0
    my_str       db 'aaa', 0

    dispatch_table:
        times ('a' + 1) dq not_command

        dq print_bin
        dq put_char
        dq print_sign_dec
        
        times ('o'-'d'-1) dq not_command

        dq print_oct

        times ('s'-'o'-1) dq not_command

        dq print_str

        times ('u'-'s'-1) dq not_command

        dq print_unsign_dec
        
        times ('x'-'u'-1) dq not_command

        dq print_hex

        times (255 - 'x') dq not_command

section .bss
    buffer resb 32

section .text
    global _start

my_printf:
    mov rdx, 0                     ; rdx = 0
    xor rcx, rcx

my_printf_iteration:

    cmp word [buf_size], max_buf_size   ; check is buffer is full
    jl buf_not_ful

    call buffer_out                 ; clean buffer
buf_not_ful:
    mov bl, byte [rsi + rcx]        ; get current smb

    cmp bl, 0                     ; check if it is end` 
    je end

    cmp bl, '%'                     ; check if it is command
    je is_command
                                    ; not command
    inc rcx                         ; rcx++
    jmp my_printf_iteration         ; next it iteration

is_command:
    mov rbx, rcx
    call my_memmove

    xor rcx, rcx

    inc rsi
    movzx rbx, byte [rsi]            ; get next smb

    inc rdx
    mov rax, [rsp + rdx * 8]        ; get param

    lea rbx, [dispatch_table + rbx * 8]
    call [rbx] ; execute command

    xor rcx, rcx                    ; rcx = 00

    inc rsi                         ; to next smb

    jmp my_printf_iteration         ; next iteration

end:                                ; finish command
    mov rbx, rcx
    call my_memmove

    call buffer_out
    ret
    
not_command:
    dec rdx
    mov rax, rbx
    call put_char

    ret

;__________________________________
; print buffer
; CHANGE: rax, rdx, rdi, rsi
;__________________________________
buffer_out:
    push rsi
    push rdx
    push rcx
    push rax

    mov rax, 1          ; write
    mov rdi, 1          ; stdout
    mov rsi, buffer     ; адрес buffer
    movzx rdx, word [buf_size] ; длина buffer
    syscall

    mov word [buf_size], 0

    pop rax
    pop rcx
    pop rdx
    pop rsi

    ret

;__________________________________
; print str fragment from memory
; ENTRY: 
;       rsi point on string
;       rdx len
; CHANGE: rax, rdi
;__________________________________
str_frag_out:
    mov rax, 1          ; write
    mov rdi, 1          ; stdout
    syscall

    mov word [buf_size], 0 

    ret

print_str:
    push rsi

    mov rsi, rax

    call strlen                 ; rbx = str len
    call my_memmove         ; put str in buf

    pop rsi
    ret

;______________________________________
; put rbx byte in buffer
; ENTRY:
;       rsi = point on mem
;       rbx = mem len
; CHANGE rbx, rcx, rsi, rdi
;______________________________________
my_memmove:
    push rdx
    push rcx
    
    movzx rdx, word [buf_size] 
    add rdx, rbx

    cmp rdx, max_buf_size
    ja buf_is_small
    
    lea rdi, [buffer + rdx]         ; rdi = point on free part of buffer
    sub rdi, rbx
    mov rcx, rbx                    ; rax = str len

    call copy_frag                  ; put str in buffer (change rsi)

    add word [buf_size], bx         ; update buf_size

    pop rcx
    pop rdx
    ret

buf_is_small:
    push rax                ; save rax
    call buffer_out         ; print buffer
    pop rax

    mov rdx, rbx            ; rdx = len
    call str_frag_out       ; print str

    add rsi, rbx

    pop rcx
    pop rdx
    ret

;_____________________________________
; find str len
; ENTRY:
;       rax = point on str
; OUT:
;       rbx = str len
; CHANGE: rbx
;_____________________________________
strlen:
    mov rbx, rax

next_strlen:
    cmp byte [rbx], 0
    je done_strlen

    inc rbx
    jmp next_strlen
done_strlen:
    sub rbx, rax

    ret

;______________________________________
; copy fragment of memory
; ENTRY:
;       rsi = source
;       rdi = dest
;       rcx = size
; CHANGE rax, rdx
;______________________________________
copy_frag:
    push rax
    push rcx

    mov rax, rcx      ; сохраним общий размер
    shr rcx, 3        ; rcx = rcx / 8 (qwords num)
    rep movsq         ; start copy

    mov rcx, rax
    and rax, 7        ; rcx 
    rep movsb         ; copy 1..7 byte

    pop rcx
    pop rax
    ret
    

;_____________________________________
; split and put one char in buffer
; ENTRY:
;       al = smb
; CHANGE: rbx
;_____________________________________
put_char:
    push rbx

    movzx rbx, word [buf_size]
    mov byte [buffer + rbx], al       ; put al
    inc word [buf_size]               ; увеличить смещение

    pop rbx
    ret

;_____________________________________
; split and put sign number in buffer (notation = 10)
; ENTRY:
;       eax = number
; CHANGE: rax, rcx, rbx
;_____________________________________
print_sign_dec:
    push rdx                          ; save rdx 
    mov ebx, 10

    cmp eax, 0
    jge not_need_minus

    movzx ecx, word [buf_size]
    mov byte [buffer + ecx], '-'      ; print '-'
    inc word [buf_size]               ; increase size

    neg eax
not_need_minus:

    call put_num_in_buf

    pop rdx
    ret

;_____________________________________
; split and put unsign number in buffer (notation = 10)
; ENTRY:
;       eax = number
; CHANGE: rax, rcx, rbx
;_____________________________________
print_unsign_dec:
    push rdx
    push rcx
    push rbx
    push rax

    mov ebx, 10
    call put_num_in_buf

    pop rax
    pop rbx
    pop rcx
    pop rdx
    ret

;_____________________________________
; split and put number in buffer (notation = 8)
; ENTRY:
;       eax = number
; CHANGE: rax, rcx, rbx
;_____________________________________
print_oct:
    push rdx

    mov ebx, 8
    call put_num_in_buf

    pop rdx
    ret

;_____________________________________
; split and put number in buffer (notation = 2)
; ENTRY:
;       par = number
; CHANGE: rax, rcx, rbx
;_____________________________________
print_bin:
    push rdx

    mov ebx, 2
    call put_num_in_buf

    pop rdx
    ret

;_____________________________________
; split and put number in buffer (notation = 16)
; ENTRY:
;       par = number
; CHANGE: rax, rcx, rbx
;_____________________________________
print_hex:
    push rdx
    push rbx
    push rcx

    mov ebx, 16
    call put_num_in_buf

    pop rcx
    pop rbx
    pop rdx
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

    movzx edx, byte [num_arr + edx]    ; change num to ascii code
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
    push -8
    push my_str
    push my_str
    mov rsi, string
    call my_printf

    mov eax, 1
    mov ebx, 0
    int 0x80
