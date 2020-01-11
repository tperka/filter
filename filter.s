
    section .text

    global filter

filter:
    push rbp
    mov rbp, rsp
lol:
    mov rax, rsi
    mul rdx
    mov r11, 3
    mov rcx, rax
loool:
    mov dl, 255
    sub dl, [rdi]
    mov [rdi], dl
    inc rdi
    loop loool    
end:
    mov rax, rdi
    mov rsp, rbp
    pop rbp
    ret